#import "MGSLayerController.h"
#import "MGSSafeAnnotation.h"
#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"


@interface MGSLayerController ()
@property(nonatomic,strong) MGSLayer* layer;
@property(nonatomic,strong) AGSLayer* nativeLayer;
@property(strong) NSSet *layerAnnotations;
@property(nonatomic,strong) NSOperationQueue *layerUpdateQueue;

// Tracks the annotations which are created from pre-existing graphics
// in the graphics layer. An example of this would be a feature layer
@property(nonatomic, strong) NSMutableSet *featureGraphics;

- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation;
- (BOOL)isFeatureGraphic:(id)graphic;
@end

@implementation MGSLayerController

- (id)init
{
    return [self initWithLayer:nil];
}

- (id)initWithLayer:(MGSLayer*)layer
{
    self = [super init];
    
    if (self) {
        self.layerAnnotations = nil;
        self.featureGraphics = [NSSet set];
        self.layerUpdateQueue = [[NSOperationQueue alloc] init];
        self.layerUpdateQueue.maxConcurrentOperationCount = 1;
        
        self.layer = layer;
        if (layer) {
            [self.layer addObserver:self
                         forKeyPath:@"annotations"
                            options:(NSKeyValueObservingOptionInitial |
                                     NSKeyValueObservingOptionNew |
                                     NSKeyValueObservingOptionOld)
                            context:nil];
        }
    }
    
    return self;
}

- (id)initWithNativeLayer:(AGSLayer*)nativeLayer
{
    self = [self initWithLayer:nil];
    
    if (self) {
        self.nativeLayer = nativeLayer;
    }
    
    return self;
}

- (void)dealloc
{
    [self.layer removeObserver:self
                    forKeyPath:@"annotations"];
}


#pragma mark - Dynamic Properties
- (AGSSpatialReference*)spatialReference
{
    // Use a direct ivar access here so we don't trigger the
    // lazy creation of a graphics layer if it doesn't exist
    if (_nativeLayer && self.nativeLayer.spatialReference) {
        return self.nativeLayer.spatialReference;
    } else {
        return _spatialReference;
    }
}

- (AGSLayer*)nativeLayer
{
    AGSGraphicsLayer *layer = nil;
    
    if (_nativeLayer == nil) {
        if ([self.delegate respondsToSelector:@selector(layerManager:graphicsLayerForLayer:)]) {
            layer = [self.delegate layerManager:self
                          graphicsLayerForLayer:self.layer];
        }
        
        if (layer == nil) {
            layer = [[AGSGraphicsLayer alloc] init];
        }
    }
    
    if (layer) {
        self.nativeLayer = layer;
        [self refresh];
    }
    
    return _nativeLayer;
}

#pragma mark -
- (MGSLayerAnnotation*)layerAnnotationForGraphic:(AGSGraphic*)graphic
{
    NSSet *annotationSet = [self layerAnnotationsForGraphics:[NSSet setWithObject:graphic]];
    return [annotationSet anyObject];
}

- (NSSet*)layerAnnotationsForGraphics:(NSSet*)graphics
{
    NSSet *allLayerAnnotations = [NSSet setWithSet:self.layerAnnotations];
    
    NSMutableSet *layerAnnotations = nil;
    if ([allLayerAnnotations count]) {
        layerAnnotations = [NSMutableSet set];
        
        [allLayerAnnotations enumerateObjectsUsingBlock:^(MGSLayerAnnotation *layerAnnotation, BOOL* stop) {
            if ([graphics containsObject:layerAnnotation.graphic]) {
                [layerAnnotations addObject:layerAnnotation];
            }
            
            (*stop) = ([layerAnnotations count] == [graphics count]);
        }];
    }
    return layerAnnotations;
}

- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation
{
    NSSet *annotationSet = [self layerAnnotationsForAnnotations:[NSSet setWithObject:annotation]];
    return [annotationSet anyObject];
}

- (NSSet*)layerAnnotationsForAnnotations:(NSSet*)annotations
{
    NSSet *allLayerAnnotations = [NSSet setWithSet:self.layerAnnotations];
    
    NSMutableSet *layerAnnotations = nil;
    if ([allLayerAnnotations count]) {
        layerAnnotations = [NSMutableSet set];
        
        [allLayerAnnotations enumerateObjectsUsingBlock:^(MGSLayerAnnotation *layerAnnotation, BOOL* stop) {
            if ([annotations containsObject:layerAnnotation.annotation]) {
                [layerAnnotations addObject:layerAnnotation];
            }
            
            (*stop) = ([layerAnnotations count] == [annotations count]);
        }];
    }
    
    return layerAnnotations;
}

- (BOOL)isFeatureGraphic:(id)graphicOrAnnotation {
    AGSGraphic *testGraphic = nil;
    
    if ([graphicOrAnnotation isKindOfClass:[AGSGraphic class]]) {
        testGraphic = (AGSGraphic*) graphicOrAnnotation;
    } else if ([graphicOrAnnotation conformsToProtocol:@protocol(MGSAnnotation)]) {
        MGSLayerAnnotation* layerAnnotation = [self layerAnnotationForAnnotation:((id<MGSAnnotation>)graphicOrAnnotation)];
        testGraphic = layerAnnotation.graphic;
    }
    
    
    return (testGraphic && [self.featureGraphics containsObject:testGraphic]);
}

- (void)refresh
{
    [self synchronizeNativeLayerWithAnnotations:self.layer.annotations
                                            old:nil];
}

// TODO: Optimize this if needed, just brute forcing it for now
- (void)synchronizeNativeLayerWithAnnotations:(NSOrderedSet*)newAnnotations
                                          old:(NSOrderedSet*)oldAnnotations
{
    BOOL canSynchronize = (self.layer &&
                           _nativeLayer &&
                           [_nativeLayer isKindOfClass:[AGSGraphicsLayer class]] &&
                           ([newAnnotations count] ||
                            [oldAnnotations count]));
    
    if (canSynchronize)
    {
        __weak AGSGraphicsLayer *graphicsLayer = (AGSGraphicsLayer*)self.nativeLayer;
        
        NSBlockOperation *blockOperation = nil;
        blockOperation = [NSBlockOperation blockOperationWithBlock:^{
            DDLogVerbose(@"Beginning layer sync: '%@' [New:%lu,Old:%lu]",
                         self.layer.name,
                         (unsigned long)[newAnnotations count],
                         (unsigned long)[oldAnnotations count]);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(layerManagerWillSynchronizeAnnotations:)]) {
                    [self.delegate layerManagerWillSynchronizeAnnotations:self];
                }
            });
            
            NSArray *annotations = [newAnnotations sortedArrayUsingComparator:^NSComparisonResult(id<MGSAnnotation> obj1, id<MGSAnnotation> obj2) {
                MGSSafeAnnotation *annotation1 = [[MGSSafeAnnotation alloc] initWithAnnotation:obj1];
                MGSSafeAnnotation *annotation2 = [[MGSSafeAnnotation alloc] initWithAnnotation:obj2];
                
                BOOL obj1_isMarker = (([annotation1 annotationType] == MGSAnnotationMarker) ||
                                      ([annotation1 annotationType] == MGSAnnotationPointOfInterest));
                
                BOOL obj2_isMarker = (([annotation2 annotationType] == MGSAnnotationMarker) ||
                                      ([annotation2 annotationType] == MGSAnnotationPointOfInterest));
                
                if (obj1_isMarker && obj2_isMarker) {
                    CLLocationCoordinate2D coordinate1 = [annotation1 coordinate];
                    CLLocationCoordinate2D coordinate2 = [annotation2 coordinate];
                    
                    if (coordinate1.latitude > coordinate2.latitude) {
                        return NSOrderedAscending;
                    }
                    else if (coordinate1.latitude < coordinate2.latitude) {
                        return NSOrderedDescending;
                    }
                    else if (coordinate1.longitude > coordinate2.longitude) {
                        return NSOrderedDescending;
                    }
                    else if (coordinate1.longitude > coordinate2.longitude) {
                        return NSOrderedDescending;
                    }
                    
                    return NSOrderedSame;
                } else if (obj1_isMarker) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }];
            
            NSMutableSet *layerAnnotations = [NSMutableSet set];
            NSMutableArray *graphics = [NSMutableArray array];
            
            for (id<MGSAnnotation> annotation in annotations) {
                AGSGraphic *annotationGraphic = [self createGraphicForAnnotation:annotation];
                MGSLayerAnnotation *layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                             graphic:annotationGraphic];
                [layerAnnotations addObject:layerAnnotation];
                [graphics addObject:annotationGraphic];
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.layerAnnotations = layerAnnotations;
                
                [graphicsLayer removeAllGraphics];
                [graphicsLayer addGraphics:graphics];
                [graphicsLayer refresh];
                
                if ([self.delegate respondsToSelector:@selector(layerManagerDidSynchronizeAnnotations:)]) {
                    [self.delegate layerManagerDidSynchronizeAnnotations:self];
                }
            });
        }];
        
        [self.layerUpdateQueue addOperation:blockOperation];
    }
}

- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation
{
    // If the delegate responds to the selector, just use the result as-is,
    // even if it is nil.
    // TODO: Make sure that whoever calls this method can handle a nil result!
    if ([self.delegate respondsToSelector:@selector(layerManager:graphicForAnnotation:)]) {
        return [self.delegate layerManager:self
                      graphicForAnnotation:annotation];
    } else {
        AGSSpatialReference *reference = self.spatialReference ? self.spatialReference : [AGSSpatialReference wgs84SpatialReference];
        MGSSafeAnnotation* safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        AGSGraphic* annotationGraphic = nil;
        
        switch (annotation.annotationType) {
            case MGSAnnotationMarker: {
                UIImage* markerImage = safeAnnotation.markerImage;
                MGSMarkerOptions options;
                
                AGSPictureMarkerSymbol* markerSymbol = nil;
                if (markerImage) {
                    markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
                    options = safeAnnotation.markerOptions;
                } else {
                    markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"map/map_pin_complete"];
                    options = MGSMarkerOptionsMake(CGPointMake(0.0, 8.0), CGPointMake(2.0, 16.0));
                }
                
                markerSymbol.leaderPoint = options.hotspot;
                markerSymbol.offset = options.offset;
                
                annotationGraphic = [[AGSGraphic alloc] initWithGeometry:AGSPointFromCLLocationCoordinate2DInSpatialReference(safeAnnotation.coordinate,reference)
                                                                  symbol:markerSymbol
                                                              attributes:[NSMutableDictionary dictionary]
                                                    infoTemplateDelegate:nil];
            }
                break;
                
            case MGSAnnotationPolyline: {
                if ([annotation respondsToSelector:@selector(points)]) {
                    AGSMutablePolyline* polyline = [[AGSMutablePolyline alloc] init];
                    polyline.spatialReference = [AGSSpatialReference wgs84SpatialReference];
                    [polyline addPathToPolyline];
                    
                    for (NSValue* pointValue in [annotation points]) {
                        CLLocationCoordinate2D point = [pointValue CLLocationCoordinateValue];
                        
                        if (CLLocationCoordinate2DIsValid(point)) {
                            AGSPoint* agsPoint = AGSPointFromCLLocationCoordinate2D(point);
                            [polyline addPointToPath:agsPoint];
                        } else {
                            DDLogVerbose(@"skipping invalid point %@", NSStringFromCLLocationCoordinate2D(point));
                        }
                    }
                    
                    UIColor* lineColor = nil;
                    CGFloat lineWidth = 0.0;
                    
                    if ([annotation respondsToSelector:@selector(strokeColor)]) {
                        lineColor = [annotation strokeColor];
                    }
                    
                    if ([annotation respondsToSelector:@selector(lineWidth)]) {
                        lineWidth = [annotation lineWidth];
                    }
                    
                    AGSSimpleLineSymbol* lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithColor:(lineColor ? lineColor : [UIColor greenColor])
                                                                                               width:((lineWidth >= 0.5) ? lineWidth : 2.0)];
                    
                    annotationGraphic = [[AGSGraphic alloc] initWithGeometry:[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polyline
                                                                                                                     toSpatialReference:reference]
                                                                      symbol:lineSymbol
                                                                  attributes:[NSMutableDictionary dictionary]
                                                        infoTemplateDelegate:nil];
                } else {
                    DDLogVerbose(@"unable to create polyline, object does not response to -[MGSAnnotation points]");
                }
            }
                break;
                
            case MGSAnnotationPolygon: {
                if ([annotation respondsToSelector:@selector(points)]) {
                    AGSMutablePolygon* polygon = [[AGSMutablePolygon alloc] init];
                    polygon.spatialReference = [AGSSpatialReference wgs84SpatialReference];
                    [polygon addRingToPolygon];
                    
                    for (NSValue* pointValue in [annotation points]) {
                        CLLocationCoordinate2D point = [pointValue CLLocationCoordinateValue];
                        
                        if (CLLocationCoordinate2DIsValid(point)) {
                            AGSPoint* agsPoint = AGSPointFromCLLocationCoordinate2D(point);
                            [polygon addPointToRing:agsPoint];
                        } else {
                            DDLogVerbose(@"skipping invalid point %@", NSStringFromCLLocationCoordinate2D(point));
                        }
                    }
                    
                    UIColor* strokeColor = nil;
                    UIColor* fillColor = nil;
                    CGFloat lineWidth = 0.0;
                    
                    if ([annotation respondsToSelector:@selector(strokeColor)]) {
                        UIColor* aStrokeColor = [annotation strokeColor];
                        
                        if (aStrokeColor == nil) {
                            strokeColor = [UIColor colorWithWhite:0.0
                                                            alpha:0.5];
                        } else {
                            strokeColor = aStrokeColor;
                        }
                    }
                    
                    if ([annotation respondsToSelector:@selector(fillColor)]) {
                        UIColor* aFillColor = [annotation fillColor];
                        
                        if (aFillColor == nil) {
                            fillColor = [UIColor colorWithWhite:0.0
                                                          alpha:0.5];
                        } else {
                            fillColor = aFillColor;
                        }
                    }
                    
                    if ([annotation respondsToSelector:@selector(lineWidth)]) {
                        lineWidth = [annotation lineWidth];
                    }
                    
                    AGSSimpleFillSymbol* fillSymbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:fillColor
                                                                                        outlineColor:strokeColor];
                    fillSymbol.outline.width = lineWidth;
                    
                    annotationGraphic = [[AGSGraphic alloc] initWithGeometry:[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polygon
                                                                                                                     toSpatialReference:reference]
                                                                      symbol:fillSymbol
                                                                  attributes:[NSMutableDictionary dictionary]
                                                        infoTemplateDelegate:nil];
                } else {
                    DDLogVerbose(@"unable to create polygon, object does not response to -[MGSAnnotation points]");
                }
            }
                break;
                
            case MGSAnnotationPointOfInterest:
                // Not sure how we'll handle this one. For the time being,
                // default to a nil graphic
            default:
                annotationGraphic = nil;
        }
        
        return annotationGraphic;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isEqual:self.layer] && [keyPath isEqualToString:@"annotations"]) {
        [self refresh];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
