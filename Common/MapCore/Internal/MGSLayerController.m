#import "MGSLayerController.h"
#import "MGSSafeAnnotation.h"
#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"


@interface MGSLayerController ()
@property(nonatomic, strong) MGSLayer* layer;
@property(weak) AGSGraphicsLayer* graphicsLayer;
@property(strong) NSSet *layerAnnotations;
@property(nonatomic, strong) NSSet *cachedAnnotations;
@property(nonatomic, strong) NSOperationQueue *layerUpdateQueue;

// Tracks the annotations which are created from pre-existing graphics
// in the graphics layer. An example of this would be a feature layer
@property(nonatomic, strong) NSMutableSet *featureGraphics;

- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation;
- (BOOL)isFeatureGraphic:(id)graphic;
@end

@implementation MGSLayerController
@dynamic allAnnotations;

- (id)initWithLayer:(MGSLayer*)layer
{
    self = [super init];
    
    if (self) {
        self.layer = layer;
        self.layerAnnotations = nil;
        self.featureGraphics = [NSMutableSet set];
        self.cachedAnnotations = [NSMutableSet set];
        self.layerUpdateQueue = [[NSOperationQueue alloc] init];
        self.layerUpdateQueue.maxConcurrentOperationCount = 1;
        
        [self.layer addObserver:self
                     forKeyPath:@"annotations"
                        options:(NSKeyValueObservingOptions)0 //Typecast so the compiler stops complaining that the NSKeyValueObservingOptions enum doesn't have a value for 0
                        context:nil];
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
    if (_graphicsLayer && self.graphicsLayer.spatialReference) {
        return self.graphicsLayer.spatialReference;
    } else {
        return _spatialReference;
    }
}

- (NSSet*)allAnnotations
{
    return [NSSet setWithSet:self.layerAnnotations];
}

- (AGSGraphicsLayer*)graphicsLayer
{
    AGSGraphicsLayer *layer = nil;
    
    if (_graphicsLayer == nil) {
        if ([self.delegate respondsToSelector:@selector(layerManager:graphicsLayerForLayer:)]) {
            layer = [self.delegate layerManager:self
                          graphicsLayerForLayer:self.layer];
        }
        
        if (layer == nil) {
            layer = [[AGSGraphicsLayer alloc] init];
        }
    }
    
    if (layer) {
        self.graphicsLayer = layer;
        [self syncAnnotations];
    }
    
    return _graphicsLayer;
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

// TODO: Optimize this if needed, just brute forcing it for now
- (void)syncAnnotations {
    if (!(self.layer && _graphicsLayer)) {
        return;
    }
    
    [self.layerUpdateQueue cancelAllOperations];
    
    NSBlockOperation *blockOperation = nil;
    blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSSet *displayedAnnotations = (self.cachedAnnotations != nil) ? self.cachedAnnotations : [NSSet set];
        NSSet *updatedAnnotations = [self.layer.annotations set];
        self.cachedAnnotations = updatedAnnotations;
        
        BOOL performSync = (([displayedAnnotations isEqualToSet:updatedAnnotations] == NO) &&
                            ([displayedAnnotations count] ||
                             [updatedAnnotations count]));
        
        if (performSync) {
            // Looks like an update is needed!
            DDLogVerbose(@"Beginning layer sync: '%@' [%lu -> %lu]",
                         self.layer.name,
                         (unsigned long)[displayedAnnotations count],
                         (unsigned long)[updatedAnnotations count]);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(layerManagerWillSynchronizeAnnotations:)]) {
                    [self.delegate layerManagerWillSynchronizeAnnotations:self];
                }
            });
            
            
            NSMutableArray *agsGraphics = [NSMutableArray arrayWithArray:self.graphicsLayer.graphics];
            NSMutableArray *sortableGraphics = [NSMutableArray array];
            NSMutableArray *deletedLayerAnnotations = [NSMutableArray array];
            NSMutableArray *addedLayerAnnotations = [NSMutableArray array];
            
            if ([blockOperation isCancelled] == NO) {
                {
                    NSMutableSet *deletedAnnotations = [displayedAnnotations mutableCopy];
                    [deletedAnnotations minusSet:updatedAnnotations];
                    NSSet *layerAnnotations = [self layerAnnotationsForAnnotations:deletedAnnotations];
                    [deletedLayerAnnotations addObjectsFromArray:[layerAnnotations allObjects]];
                    
                    [layerAnnotations enumerateObjectsUsingBlock:^(MGSLayerAnnotation* layerAnnotation, BOOL* stop) {
                        if (layerAnnotation.graphic) {
                            [agsGraphics removeObject:layerAnnotation.graphic];
                        }
                    }];
                }
            
                {
                    NSMutableSet *addedAnnotations = [updatedAnnotations mutableCopy];
                    [addedAnnotations minusSet:displayedAnnotations];
                    
                    [addedAnnotations enumerateObjectsUsingBlock:^(id<MGSAnnotation> annotation, BOOL* stop) {
                        AGSGraphic *graphic = [self createGraphicForAnnotation:annotation];
                        
                        MGSLayerAnnotation *layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                                     graphic:graphic];
                        [addedLayerAnnotations addObject:layerAnnotation];
                        
                        if (graphic) {
                            MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
                            BOOL needsSorting = ((safeAnnotation.annotationType == MGSAnnotationMarker) ||
                                                 (safeAnnotation.annotationType == MGSAnnotationPointOfInterest));
                            if (needsSorting) {
                                if ([agsGraphics containsObject:graphic]) {
                                    [agsGraphics removeObject:graphic];
                                }
                                
                                [sortableGraphics addObject:graphic];
                            } else {
                                [agsGraphics addObject:graphic];
                            }
                        }
                    }];
                }
            }
            
            
            if ([blockOperation isCancelled] == NO) {
                [sortableGraphics sortUsingComparator:^(AGSGraphic* graphic1, AGSGraphic* graphic2) {
                    AGSPoint *point1 = graphic1.geometry.envelope.center;
                    AGSPoint *point2 = graphic2.geometry.envelope.center;
                    
                    if (point1.y > point2.y) {
                        return NSOrderedAscending;
                    }
                    else if (point1.y < point2.y) {
                        return NSOrderedDescending;
                    }
                    else if (point1.x > point2.x) {
                        return NSOrderedDescending;
                    }
                    else if (point1.x < point2.x) {
                        return NSOrderedDescending;
                    }
                    
                    return NSOrderedSame;
                }];
                
                [agsGraphics addObjectsFromArray:sortableGraphics];
                
                // Make sure everything is in the correct spatial reference!
                [agsGraphics enumerateObjectsUsingBlock:^(AGSGraphic* graphic, NSUInteger index, BOOL* stop) {
                    // Reproject all the things!
                    BOOL shouldReproject = (graphic.geometry &&
                                            ([graphic.geometry.spatialReference isEqualToSpatialReference:self.spatialReference] == NO));
                    if (shouldReproject) {
                        graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                                   toSpatialReference:self.spatialReference];
                    }
                }];
            }
            
            
            if ([blockOperation isCancelled] == NO) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.cachedAnnotations = updatedAnnotations;
                    NSMutableSet *layerAnnotations = [NSMutableSet setWithSet:self.layerAnnotations];
                    
                    [layerAnnotations minusSet:[NSSet setWithArray:deletedLayerAnnotations]];
                    [layerAnnotations unionSet:[NSSet setWithArray:addedLayerAnnotations]];
                    self.layerAnnotations = layerAnnotations;
                    
                    [self.graphicsLayer removeGraphics:self.graphicsLayer.graphics];
                    [self.graphicsLayer addGraphics:agsGraphics];
                    [self.graphicsLayer refresh];
                });
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(layerManagerDidSynchronizeAnnotations:)]) {
                    [self.delegate layerManagerDidSynchronizeAnnotations:self];
                }
            });
        }
    }];
    
    [self.layerUpdateQueue addOperation:blockOperation];
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
        [self syncAnnotations];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
