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
@property(copy) NSOrderedSet *currentAnnotations;
@property BOOL layerNeedsRefresh;

@property dispatch_queue_t refreshQueue;
@property dispatch_semaphore_t refreshSemaphore;

- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation;
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
        
        self.layer = layer;
        
        self.refreshSemaphore = dispatch_semaphore_create(1);
        self.refreshQueue = dispatch_get_main_queue();
        
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

- (void)dealloc
{
    if (self.refreshSemaphore) {
        dispatch_release(self.refreshSemaphore);
        self.refreshSemaphore = NULL;
    }
    
    if (self.refreshQueue && (self.refreshQueue != dispatch_get_main_queue())) {
        dispatch_release(self.refreshQueue);
        self.refreshQueue = NULL;
    }
    
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
            layer.renderNativeResolution = YES;
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

- (void)refresh
{
    [self synchronizeNativeLayerWithAnnotations:self.layer.annotations
                                    forceReload:NO];
}

- (void)reload
{
    [self synchronizeNativeLayerWithAnnotations:self.layer.annotations
                                    forceReload:YES];
}

// TODO: Optimize this if needed, just brute forcing it for now
- (void)synchronizeNativeLayerWithAnnotations:(NSOrderedSet*)newAnnotations
                                  forceReload:(BOOL)forceReload
{
    NSOrderedSet *oldAnnotations = forceReload ? [NSOrderedSet orderedSet] : self.currentAnnotations;
    
    BOOL hasValidNativeLayer = (self.layer &&
                                _nativeLayer &&
                                [_nativeLayer isKindOfClass:[AGSGraphicsLayer class]] &&
                                self.spatialReference);
    
    if (!hasValidNativeLayer) {
        return;
    } else {
        if (!dispatch_semaphore_wait(self.refreshSemaphore, DISPATCH_TIME_NOW)) {
            __weak AGSGraphicsLayer *graphicsLayer = (AGSGraphicsLayer*)self.nativeLayer;
            self.layerNeedsRefresh = NO;
            
            dispatch_async(self.refreshQueue, ^{
                dispatch_block_t willSynchronizeBlock = ^{
                    if ([self.delegate respondsToSelector:@selector(layerManagerWillSynchronizeAnnotations:)]) {
                        [self.delegate layerManagerWillSynchronizeAnnotations:self];
                    }
                };
                
                if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
                    willSynchronizeBlock();
                } else {
                    dispatch_sync(dispatch_get_main_queue(), willSynchronizeBlock);
                }
                
                BOOL annotationsUpdated = (([newAnnotations count] ||
                                            [oldAnnotations count]) &&
                                           ([[oldAnnotations set] isEqualToSet:[newAnnotations set]] == NO));
                
                if (annotationsUpdated) {
                    DDLogVerbose(@"Beginning layer sync: '%@' [New:%lu,Old:%lu]",
                                 self.layer.name,
                                 (unsigned long)[newAnnotations count],
                                 (unsigned long)[oldAnnotations count]);
                    
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
                            return NSOrderedDescending;
                        } else {
                            return NSOrderedAscending;
                        }
                    }];
                    
                    NSMutableSet *layerAnnotations = [NSMutableSet set];
                    NSMutableArray *graphics = [NSMutableArray array];
                    
                    for (id<MGSAnnotation> annotation in annotations) {
                        AGSGraphic *annotationGraphic = [self createGraphicForAnnotation:annotation];
                        
                        if ([self.spatialReference isEqualToSpatialReference:annotationGraphic.geometry.spatialReference] == NO) {
                            annotationGraphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:annotationGraphic.geometry
                                                                                                 toSpatialReference:self.spatialReference];
                        }
                        
                        MGSLayerAnnotation *layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                                     graphic:annotationGraphic];
                        [layerAnnotations addObject:layerAnnotation];
                        [graphics addObject:annotationGraphic];
                    }
                    
                    dispatch_block_t updateStateBlock = ^{
                        self.currentAnnotations = newAnnotations;
                        self.layerAnnotations = layerAnnotations;
                        
                        [graphicsLayer removeAllGraphics];
                        [graphicsLayer addGraphics:graphics];
                        [graphicsLayer refresh];
                    };
                    
                    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
                        updateStateBlock();
                    } else {
                        dispatch_sync(dispatch_get_main_queue(), updateStateBlock);
                    }
                }
                
                dispatch_block_t didSynchronizeBlock = ^{
                    if ([self.delegate respondsToSelector:@selector(layerManagerDidSynchronizeAnnotations:)]) {
                        [self.delegate layerManagerDidSynchronizeAnnotations:self];
                    }
                    
                    dispatch_semaphore_signal(self.refreshSemaphore);
                    if (self.layerNeedsRefresh) {
                        if (forceReload) {
                            [self reload];
                        } else {
                            [self refresh];
                        }
                    }
                };
                
                if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
                    didSynchronizeBlock();
                } else {
                    dispatch_async(dispatch_get_main_queue(), didSynchronizeBlock);
                }
            });
        } else {
            self.layerNeedsRefresh = YES;
        }
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
        MGSLayer *layer = (MGSLayer*)object;
        [self synchronizeNativeLayerWithAnnotations:layer.annotations
                                        forceReload:NO];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
