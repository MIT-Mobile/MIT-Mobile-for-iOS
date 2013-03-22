#import "MGSLayerManager.h"
#import "MGSSafeAnnotation.h"
#import "MGSUtility.h"
#import "CoreLocation+MITAdditions.h"
#import "MGSLayer.h"


@interface MGSLayerManager ()
@property(nonatomic, strong) MGSLayer* layer;
@property(nonatomic, strong) AGSGraphicsLayer* graphicsLayer;
@property(nonatomic, strong) NSSet *cachedAnnotations;
@property(nonatomic, readonly) AGSSpatialReference *spatialReference;

// Tracks any added MGSAnnotation objects and their 
@property(nonatomic, strong) NSMutableDictionary *annotationMap;

- (AGSGraphicsLayer*)createGraphicsLayer;
- (AGSGraphic*)createGraphicForAnnotation:(id <MGSAnnotation>)annotation;
@end

@implementation MGSLayerManager
@dynamic spatialReference;

- (id)initWithLayer:(MGSLayer*)layer
{
    self = [super init];

    if (self) {
        self.layer = layer;
        self.annotationMap = [NSMutableDictionary dictionary];
    }

    return self;
}

#pragma mark - Dynamic Properties
- (AGSSpatialReference*)spatialReference
{
    AGSSpatialReference *reference = [AGSSpatialReference webMercatorSpatialReference];
    
    if (self.graphicsLayer.spatialReferenceStatusValid == NO) {
        if (self.defaultSpatialReference) {
            reference = self.defaultSpatialReference;
        }
    } else {
        reference = self.graphicsLayer.spatialReference;
    }
    
    return reference;
}

- (AGSGraphicsLayer*)graphicsLayer
{
    if ((self->_graphicsLayer == nil) && self.spatialReference) {
        self->_graphicsLayer = [self createGraphicsLayer];

        [self syncAnnotations];
    }

    return self->_graphicsLayer;
}
#pragma mark -

- (void)setGraphic:(AGSGraphic*)graphic forAnnotation:(id<MGSAnnotation>)annotation
{
    if (self.annotationMap[annotation]) {
        AGSGraphic *graphic = self.annotationMap[annotation];
        [self.graphicsLayer removeGraphic:graphic];
        [self.annotationMap removeObjectForKey:annotation];
    }
}

- (AGSGraphic*)graphicForAnnotation:(id <MGSAnnotation>)annotation
{

}


- (void)setAnnotation:(id<MGSAnnotation>)annotation forGraphic:(AGSGraphic*)graphic
{
    
}

- (id <MGSAnnotation>)annotationForGraphic:(AGSGraphic*)graphic
{

}

- (void)syncAnnotations {
    if (!(self.layer && self.graphicsLayer)) {
        return;
    }

    NSSet *currentAnnotations = [NSSet setWithArray:self.layer.annotations];
    
    NSMutableSet *deletedAnnotations = [NSMutableSet setWithSet:self.cachedAnnotations];
    [deletedAnnotations minusSet:currentAnnotations];
    
    for (id<MGSAnnotation> annotation in deletedAnnotations) {
        
    }
    
    
    NSMutableSet *addedAnnotations = [NSMutableSet setWithSet:currentAnnotations];
    [addedAnnotations minusSet:self.cachedAnnotations];
}

- (AGSGraphicsLayer*)createGraphicsLayer
{
    if ([self.delegate respondsToSelector:@selector(layerManager:graphicsLayerForLayer:)]) {
        return [self.delegate layerManager:self
                     graphicsLayerForLayer:self.layer];
    } else {

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
                    markerSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"map/map_pin_complete"]];
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
@end
