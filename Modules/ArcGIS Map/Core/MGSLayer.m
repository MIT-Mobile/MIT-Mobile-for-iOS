#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGSLayer+Subclass.h"
#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"

#import "MGSMapView.h"

#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MapKit+MITAdditions.h"
#import "MGSCalloutView.h"

@interface MGSLayer () <AGSLayerDelegate>
@property (nonatomic,strong) NSMutableArray *layerAnnotations;

@end

@implementation MGSLayer
@dynamic annotations;
@dynamic hasGraphicsLayer;

#pragma mark - Class Methods

+ (MKCoordinateRegion)regionForAnnotations:(NSSet *)annotations {
    NSMutableArray *coordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations) {
        MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
        
        switch (safeAnnotation.annotationType) {
            case MGSAnnotationMarker:
            case MGSAnnotationPointOfInterest: {
                [coordinates addObject:[NSValue valueWithCLLocationCoordinate:safeAnnotation.coordinate]];
            }
                break;
                
            case MGSAnnotationPolygon:
            case MGSAnnotationPolyline: {
                if ([safeAnnotation.points count]) {
                    [coordinates addObjectsFromArray:safeAnnotation.points];
                }
            }
                break;
        }
    }
    
    return MKCoordinateRegionForCoordinates([NSSet setWithArray:coordinates]);
}

- (id)init {
    return [self initWithName:nil];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        self.name = name;
        self.layerAnnotations = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Property Accessor/Mutators
- (void)setMapView:(MGSMapView *)mapView {
    if ([_mapView isEqual:mapView] == NO) {
        [self willMoveToMapView:mapView];
        _mapView = mapView;
        [self didMoveToMapView:mapView];
    }
}

- (void)setAnnotations:(NSArray *)annotations {
    if (self.annotations) {
        [self deleteAllAnnotations];
    }
    
    [self addAnnotations:annotations];
}

- (NSArray *)annotations {
    NSMutableArray *extAnnotations = [NSMutableArray array];
    for (MGSLayerAnnotation *annotation in self.layerAnnotations) {
        [extAnnotations addObject:annotation.annotation];
    }
    
    return extAnnotations;
}

#pragma mark - Public Methods
- (void)addAnnotation:(id <MGSAnnotation>)annotation {
    [self addAnnotations:@[ annotation ]];
}

- (void)addAnnotations:(NSArray *)annotations {
    NSMutableArray *newAnnotations = [NSMutableArray arrayWithArray:annotations];
    [newAnnotations removeObjectsInArray:self.annotations];
    
    if ([newAnnotations count]) {
        [self willAddAnnotations:newAnnotations];
        
        // Sort the add order of the annotations so they are added
        // top to bottom (prevents higher markers from being overlayed
        // on top of lower ones) and left to right
        NSArray *sortedAnnotations = [newAnnotations sortedArrayUsingComparator:^NSComparisonResult(id <MGSAnnotation> obj1, id <MGSAnnotation> obj2) {
            CLLocationCoordinate2D point1 = obj1.coordinate;
            CLLocationCoordinate2D point2 = obj2.coordinate;
            
            if (point1.latitude > point2.latitude) {
                return NSOrderedAscending;
            }
            else if (point1.latitude < point2.latitude) {
                return NSOrderedDescending;
            }
            else if (point1.longitude > point2.longitude) {
                return NSOrderedDescending;
            }
            else if (point1.longitude < point2.longitude) {
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }];
        
        for (id <MGSAnnotation> annotation in sortedAnnotations) {
            MGSLayerAnnotation *mapAnnotation = nil;
            
            if ([annotation isKindOfClass:[MGSLayerAnnotation class]]) {
                mapAnnotation = (MGSLayerAnnotation *) annotation;
                
                // Make sure some other layer doesn't already have a claim on this
                // annotation and, if one does, we need to create a new layer annotation
                // which wraps the annotation we are working with
                if ((mapAnnotation.layer != nil) && (mapAnnotation.layer != self)) {
                    mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:mapAnnotation.annotation
                                                                           graphic:nil];
                }
            }
            
            if (mapAnnotation == nil) {
                mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                       graphic:nil];
            }
            
            mapAnnotation.layer = self;
            
            [self.layerAnnotations addObject:mapAnnotation];
        }
        
        [self didAddAnnotations:newAnnotations];
    }
}

- (void)insertAnnotation:(id<MGSAnnotation>)annotation atIndex:(NSUInteger)index {
    MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
    if (layerAnnotation) {
        [self.layerAnnotations removeObject:layerAnnotation];
    } else {
        [self willAddAnnotations:@[annotation]];
        
        if ([annotation isKindOfClass:[MGSLayerAnnotation class]]) {
            MGSLayerAnnotation *existingAnnotation = (MGSLayerAnnotation *) annotation;
            
            // Make sure some other layer doesn't already have a claim on this
            // annotation and, if one does, we need to create a new layer annotation
            // which wraps the annotation we are working with
            if ((existingAnnotation.layer != nil) && (existingAnnotation.layer != self)) {
                layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:existingAnnotation.annotation
                                                                         graphic:nil];
            }
        }
        
        if (layerAnnotation == nil) {
            layerAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                     graphic:nil];
        }
        
        layerAnnotation.layer = self;
        
        [self didAddAnnotations:@[annotation]];
    }
    
    [self.layerAnnotations insertObject:layerAnnotation
                                atIndex:index];
    
}

- (void)deleteAnnotation:(id <MGSAnnotation>)annotation {
    if (annotation && [self.layerAnnotations containsObject:annotation]) {
        if ([self.mapView.calloutAnnotation isEqual:annotation]) {
            [self.mapView dismissCallout];
        }
        
        MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
        layerAnnotation.layer = nil;
        [self.graphicsLayer removeGraphic:layerAnnotation.graphic];
        [self.layerAnnotations removeObject:layerAnnotation];
    }
}

- (void)deleteAnnotations:(NSArray *)annotations {
    if ([annotations count]) {
        [self willRemoveAnnotations:annotations];
        
        for (id <MGSAnnotation> annotation in annotations) {
            MGSLayerAnnotation *mapAnnotation = [self layerAnnotationForAnnotation:annotation];
            
            [self.layerAnnotations removeObject:mapAnnotation];
            [self.graphicsLayer removeGraphic:mapAnnotation.graphic];
        }
        
        [self didRemoveAnnotations:annotations];
    }
}

- (void)deleteAllAnnotations {
    [self deleteAnnotations:self.annotations];
}

- (void)centerOnAnnotation:(id <MGSAnnotation>)annotation {
    if ([self.annotations containsObject:annotation]) {
        [self.mapView centerAtCoordinate:annotation.coordinate];
    }
}

- (MKCoordinateRegion)regionForAnnotations {
    return [MGSLayer regionForAnnotations:[NSSet setWithArray:self.layerAnnotations]];
}

#pragma mark - Class Extension methods
- (MGSLayerAnnotation *)layerAnnotationForAnnotation:(id <MGSAnnotation>)annotation {
    __block void *layerAnnotation = nil;
    
    // Using OSAtomicCompareAndSwapPtrBarrier so we have atomic pointer
    // assignments since the array is going to be enumerated concurrently
    // and I'd rather not deal with odd race conditions since a standard
    // if-nil-else is not atomic.
    [self.layerAnnotations enumerateObjectsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(MGSLayerAnnotation *obj, NSUInteger idx, BOOL *stop) {
                                                if ([obj.annotation isEqual:annotation]) {
                                                    (*stop) = YES;
                                                    OSAtomicCompareAndSwapPtrBarrier(nil, (__bridge void *) (obj), &layerAnnotation);
                                                }
                                            }];
    
    return (__bridge MGSLayerAnnotation *) layerAnnotation;
}

// This method should return an AGSGraphic object suitable for
// displaying the given annotation on a map view. The default
// implementation will just return nil. Graphics
// can be pretty messy objects so we'll just leave it to any
// subclasses to implement properly.
- (AGSGraphic *)createGraphicForAnnotation:(id <MGSAnnotation>)annotation
                      withSpatialReference:(AGSSpatialReference*)reference {
    MGSSafeAnnotation *safeAnnotation = [[MGSSafeAnnotation alloc] initWithAnnotation:annotation];
    AGSGraphic *annotationGraphic = nil;
    
    switch (annotation.annotationType) {
        case MGSAnnotationMarker: {
            UIImage *markerImage = safeAnnotation.markerImage;
            MGSMarkerOptions options;
            
            AGSPictureMarkerSymbol *markerSymbol = nil;
            if (markerImage) {
                markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:markerImage];
                options = safeAnnotation.markerOptions;
            } else {
                markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"map/map_pin_complete"]];
                options = MGSMarkerOptionsMake(CGPointMake(0.0, 8.0), CGPointMake(2.0, 16.0));
            }

            markerSymbol.leaderPoint = options.hotspot;
            markerSymbol.offset = options.offset;
            
            annotationGraphic = [[AGSGraphic alloc] initWithGeometry:AGSPointFromCLLocationCoordinate2DInSpatialReference(annotation.coordinate, reference)
                                                              symbol:markerSymbol
                                                          attributes:[NSMutableDictionary dictionary]
                                                infoTemplateDelegate:nil];
        }
            break;
            
        case MGSAnnotationPolyline: {
            if ([annotation respondsToSelector:@selector(points)]) {
                AGSMutablePolyline *polyline = [[AGSMutablePolyline alloc] init];
                polyline.spatialReference = [AGSSpatialReference wgs84SpatialReference];
                [polyline addPathToPolyline];
                
                for (NSValue *pointValue in [annotation points]) {
                    CLLocationCoordinate2D point = [pointValue CLLocationCoordinateValue];
                    
                    if (CLLocationCoordinate2DIsValid(point)) {
                        AGSPoint *agsPoint = AGSPointFromCLLocationCoordinate2D(point);
                        [polyline addPointToPath:agsPoint];
                    } else {
                        DDLogVerbose(@"skipping invalid point %@", NSStringFromCLLocationCoordinate2D(point));
                    }
                }
                
                UIColor *lineColor = nil;
                CGFloat lineWidth = 0.0;
                
                if ([annotation respondsToSelector:@selector(strokeColor)]) {
                    lineColor = [annotation strokeColor];
                }
                
                if ([annotation respondsToSelector:@selector(lineWidth)]) {
                    lineWidth = [annotation lineWidth];
                }
                
                AGSSimpleLineSymbol *lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithColor:(lineColor ? lineColor : [UIColor greenColor])
                                                                                           width:((lineWidth >= 0.5) ? lineWidth : 2.0)];

                if (reference != nil) {
                    polyline = (AGSMutablePolyline *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polyline
                                                                                              toSpatialReference:reference];
                }

                annotationGraphic = [[AGSGraphic alloc] initWithGeometry:polyline
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
                AGSMutablePolygon *polygon = [[AGSMutablePolygon alloc] init];
                polygon.spatialReference = [AGSSpatialReference wgs84SpatialReference];
                [polygon addRingToPolygon];
                
                for (NSValue *pointValue in [annotation points]) {
                    CLLocationCoordinate2D point = [pointValue CLLocationCoordinateValue];
                    
                    if (CLLocationCoordinate2DIsValid(point)) {
                        AGSPoint *agsPoint = AGSPointFromCLLocationCoordinate2D(point);
                        [polygon addPointToRing:agsPoint];
                    } else {
                        DDLogVerbose(@"skipping invalid point %@", NSStringFromCLLocationCoordinate2D(point));
                    }
                }
                
                UIColor *strokeColor = nil;
                UIColor *fillColor = nil;
                CGFloat lineWidth = 0.0;
                
                if ([annotation respondsToSelector:@selector(strokeColor)]) {
                    UIColor *aStrokeColor = [annotation strokeColor];
                    
                    if (aStrokeColor == nil) {
                        strokeColor = [UIColor colorWithWhite:0.0
                                                        alpha:0.5];
                    } else {
                        strokeColor = aStrokeColor;
                    }
                }
                
                if ([annotation respondsToSelector:@selector(fillColor)]) {
                    UIColor *aFillColor = [annotation fillColor];
                    
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

                AGSSimpleFillSymbol *fillSymbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:fillColor
                                                                                    outlineColor:strokeColor];
                fillSymbol.outline.width = lineWidth;

                if (reference != nil) {
                    polygon = (AGSMutablePolygon *) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:polygon
                                                                                            toSpatialReference:reference];
                }
                
                annotationGraphic = [[AGSGraphic alloc] initWithGeometry:polygon
                                                                  symbol:fillSymbol
                                                              attributes:[NSMutableDictionary dictionary]
                                                    infoTemplateDelegate:nil];
            } else {
                DDLogVerbose(@"unable to create polygon, object does not response to -[MGSAnnotation points]");
            }
        }
            break;
            
        case MGSAnnotationPointOfInterest: {
            // Not sure how we'll handle this one. For the time being,
            // default to a nil graphic and, instead, ask the subclass to
            // handle it.
            annotationGraphic = [self loadGraphicForAnnotation:annotation];
        }
            break;
            
        default:
            annotationGraphic = nil;
    }
    
    return annotationGraphic;
}

#pragma mark - ArcGIS Methods
- (AGSGraphic*)graphicForAnnotation:(id<MGSAnnotation>)annotation {
    MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
    return layerAnnotation.graphic;
}

- (id<MGSAnnotation>)annotationForGraphic:(AGSGraphic*)graphic {
    for (MGSLayerAnnotation *layerAnnotation in self.layerAnnotations) {
        if ([layerAnnotation.graphic isEqual:graphic]) {
            return layerAnnotation.annotation;
        }
    }
    
    return nil;
}

- (void)setGraphicsLayer:(AGSGraphicsLayer *)graphicsLayer {
    graphicsLayer.delegate = self;
    _graphicsLayer = graphicsLayer;
}

- (void)loadGraphicsLayer {
    AGSGraphicsLayer *graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self setGraphicsLayer:graphicsLayer];
}

- (void)refreshLayer {
    AGSGraphicsLayer *graphicsLayer = self.graphicsLayer;
    
    if (graphicsLayer == nil) {
        // No graphics layer and we don't want to forcefully
        // create one here so just return.
        return;
    } else if (graphicsLayer.spatialReferenceStatusValid == NO) {
        return;
    }
    
    graphicsLayer.visible = NO;
    [graphicsLayer removeAllGraphics];
    
    [self willReloadMapLayer];
    
    // Since a subclass may add graphics in the -didReloadMapLayer method,
    // be sure to go through and re-project everything *after* the delegation
    // call.
    AGSSpatialReference *spatialReference = nil;
    if (self.graphicsLayer.spatialReference && self.graphicsLayer.spatialReferenceStatusValid) {
        spatialReference = self.graphicsLayer.spatialReference;
    } else if (self.graphicsLayer.mapView.spatialReference) {
        spatialReference = self.graphicsLayer.mapView.spatialReference;
    } else {
        DDLogError(@"unable to find a suitable spatial reference");
        spatialReference = [AGSSpatialReference wgs84SpatialReference];
    }
    
    // Sync our current annotations with the graphics. Updating
    // each graphic for possible annotation changes could be a pain in the
    // ass so just brute force it for now; this may need to be
    // optimized in the future.
    NSMutableArray *graphics = [NSMutableArray array];
    for (MGSLayerAnnotation *layerAnnotation in self.layerAnnotations) {
        layerAnnotation.graphic = [self createGraphicForAnnotation:layerAnnotation.annotation
                                              withSpatialReference:spatialReference];
        
        if (layerAnnotation.graphic.infoTemplateDelegate == nil) {
            layerAnnotation.graphic.infoTemplateDelegate = layerAnnotation;
        }
        
        if (layerAnnotation.graphic) {
            [graphics addObject:layerAnnotation.graphic];
        }
    }
    
    [self didReloadMapLayer];
    
    DDLogVerbose(@"using spatial reference '%@', checking %d graphics", spatialReference, [graphics count]);
    
    NSUInteger reprojectionCount = 0;
    for (AGSGraphic *graphic in graphics) {
        // Only reproject on a spatial reference mismatch
        if ([graphic.geometry.spatialReference isEqualToSpatialReference:spatialReference] == NO) {
            DDLogVerbose(@"<%@> sref:\n\tMap: %@\n\tLayer: %@\n\tGraphic: %@",
                         self.name,
                         spatialReference,
                         self.graphicsLayer.spatialReference,
                         graphic.geometry.spatialReference);
            
            ++reprojectionCount;
            graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                       toSpatialReference:spatialReference];
        }
    }
    
    if (reprojectionCount > 0) {
        DDLogVerbose(@"\tReprojected %lu graphics", (unsigned long) reprojectionCount);
    }
    
    [graphicsLayer addGraphics:graphics];
    graphicsLayer.visible = YES;
}

- (void)setHidden:(BOOL)hidden {
    if (_hidden != hidden) {
        _hidden = hidden;
        self.graphicsLayer.visible = hidden;
    }
}

- (NSArray*)internalAnnotations {
    return [NSArray arrayWithArray:self.layerAnnotations];
}

#pragma mark - Map Layer Delegation
- (void)willMoveToMapView:(MGSMapView *)mapView {
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)]) {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)didMoveToMapView:(MGSMapView *)mapView {
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)]) {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)willAddAnnotations:(NSArray *)annotations {
    [self willChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:willAddAnnotations:)]) {
        [self.delegate mapLayer:self
             willAddAnnotations:annotations];
    }
}

- (void)didAddAnnotations:(NSArray *)annotations {
    [self didChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:didAddAnnotations:)]) {
        [self.delegate mapLayer:self
              didAddAnnotations:annotations];
    }
}

- (void)willRemoveAnnotations:(NSArray *)annotations {
    [self willChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSArray *)annotations {
    [self didChangeValueForKey:@"annotations"];
    
    if ([self.delegate respondsToSelector:@selector(mapLayer:didRemoveAnnotations:)]) {
        [self.delegate mapLayer:self
           didRemoveAnnotations:annotations];
    }
}

- (void)willReloadMapLayer {
    if ([self.delegate respondsToSelector:@selector(willReloadMapLayer:)]) {
        [self.delegate willReloadMapLayer:self];
    }
}

- (void)didReloadMapLayer {
    if ([self.delegate respondsToSelector:@selector(didReloadMapLayer:)]) {
        [self.delegate willReloadMapLayer:self];
    }
}

- (AGSGraphic*)loadGraphicForAnnotation:(id<MGSAnnotation>)annotation {
    /* Do nothing, leave it up to a subclass to implement this */
    return nil;
}

#pragma mark - AGSLayerDelegate Methods
- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error {
    if (self.graphicsLayer) {
        [self.graphicsLayer.mapView removeMapLayer:layer];
        self.graphicsLayer = nil;
    }
    
    DDLogError(@"graphics layer failed to load for '%@' with error '%@'",self.name, [error localizedDescription]);
}

- (void)layer:(AGSLayer *)layer didInitializeSpatialReferenceStatus:(BOOL)srStatusValid {
    DDLogInfo(@"initialized spatial reference for '%@' to %@", self.name, self.graphicsLayer.spatialReference);
    [self refreshLayer];
}

- (void)layerDidLoad:(AGSLayer *)layer {
    DDLogInfo(@"successfully loaded graphics layer for '%@'",self.name);
}

@end
