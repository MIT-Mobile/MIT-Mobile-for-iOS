#import "MGSLayerController.h"
#import "MGSSafeAnnotation.h"
#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"


@interface MGSLayerController ()
@property(nonatomic,strong) MGSLayer* layer;
@property(strong) NSSet *layerAnnotations;
@property(copy) NSSet *synchronizedAnnotations;
@property (nonatomic,strong) NSMutableSet *notificationBlocks;
@property BOOL needsRefresh;

@property NSOperationQueue *queue;

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
        self.layer = layer;
        self.notificationBlocks = [[NSMutableSet alloc] init];
        self.queue = [[NSOperationQueue alloc] init];
        [self.queue setMaxConcurrentOperationCount:1];
        
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
    [self.layer removeObserver:self
                    forKeyPath:@"annotations"];
}

- (void)setNeedsRefresh
{
    self.needsRefresh = YES;
}


#pragma mark - Dynamic Properties
- (AGSSpatialReference*)spatialReference
{
    if (self.nativeLayer && self.nativeLayer.spatialReference) {
        return self.nativeLayer.spatialReference;
    } else {
        return _spatialReference;
    }
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

- (void)refresh:(void (^)(void))completedBlock {
    dispatch_block_t localBlock = [completedBlock copy];
    [self.queue addOperationWithBlock:^{
        NSMutableSet *pendingNotifications = nil;
        
        // Check for more than 1 pending operation.
        // The operation 0 will be this block but if there are more behind it,
        // we want to merge all the notification block together and only refresh
        // once.
        if ((self.spatialReference == nil) || ([self.queue operationCount] > 1)) {
            if (localBlock) {
                [self.notificationBlocks addObject:localBlock];
            }
        } else {
            if (self.nativeLayer == nil) {
                return;
            } else if (self.needsRefresh) {
                AGSSpatialReference *spatialReference = self.spatialReference;
                NSOrderedSet *orderedAnnotations = [NSOrderedSet orderedSetWithOrderedSet:self.layer.annotations];
                
                DDLogVerbose(@"Refreshing '%@' - %lu annotations",
                             [[self.layer.name componentsSeparatedByString:@"."] lastObject],
                             (unsigned long) [orderedAnnotations count]);
                
                if ([self.delegate respondsToSelector:@selector(layerControllerWillRefresh:)])
                {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.delegate layerControllerWillRefresh:self];
                    });
                }
                
                NSArray *annotations = [orderedAnnotations sortedArrayUsingComparator:^NSComparisonResult(id <MGSAnnotation> obj1, id <MGSAnnotation> obj2) {
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
                
                for (id <MGSAnnotation> annotation in annotations) {
                    AGSGraphic *annotationGraphic = [self createGraphicForAnnotation:annotation];
                    
                    if ([spatialReference isEqualToSpatialReference:annotationGraphic.geometry.spatialReference] == NO) {
                        annotationGraphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:annotationGraphic.geometry
                                                                                             toSpatialReference:spatialReference];
                    }
                    
                    MGSLayerAnnotation *layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                                 graphic:annotationGraphic];
                    [layerAnnotations addObject:layerAnnotation];
                    [graphics addObject:annotationGraphic];
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.synchronizedAnnotations = [orderedAnnotations set];
                    self.layerAnnotations = layerAnnotations;
                    
                    if ([self.nativeLayer isKindOfClass:[AGSGraphicsLayer class]]) {
                        AGSGraphicsLayer *graphicsLayer = (AGSGraphicsLayer *) self.nativeLayer;
                        [graphicsLayer removeAllGraphics];
                        [graphicsLayer addGraphics:graphics];
                        [graphicsLayer refresh];
                    }
                });
            }
            
            pendingNotifications = [NSMutableSet setWithSet:self.notificationBlocks];
            [self.notificationBlocks removeAllObjects];
            
            if (localBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    localBlock();
                });
            }
            
            [pendingNotifications enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                dispatch_block_t block = (dispatch_block_t) obj;
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                });
            }];
            
            
            if ([self.delegate respondsToSelector:@selector(layerControllerDidRefresh:)])
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate layerControllerDidRefresh:self];
                });
                
            }
        }
    }];
}

- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation
{
    AGSSpatialReference *reference = self.spatialReference ? self.spatialReference : [AGSSpatialReference wgs84SpatialReference];
    MGSSafeAnnotation* safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
    AGSGraphic* annotationGraphic = nil;
    
    switch (safeAnnotation.annotationType) {
        case MGSAnnotationMarker: {
            UIImage* markerImage = safeAnnotation.markerImage;
            MGSMarkerOptions options;
            
            AGSPictureMarkerSymbol* markerSymbol = nil;
            if (markerImage) {
                markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
                options = safeAnnotation.markerOptions;
            } else {
                markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:MITImageMapAnnotationPin];
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
                    CLLocationCoordinate2D point = [pointValue MKCoordinateValue];
                    
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
                    CLLocationCoordinate2D point = [pointValue MKCoordinateValue];
                    
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isEqual:self.layer] && [keyPath isEqualToString:@"annotations"]) {
        [self setNeedsRefresh];
        [self refresh:nil];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
