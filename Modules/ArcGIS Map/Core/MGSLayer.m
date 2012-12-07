#import <ArcGIS/ArcGIS.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"

#import "MGSMapView.h"
#import "MGSAnnotation.h"

#import "MGSMarker.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

#import "MGSMapLayer+Protected.h"
#import "MGSUtility.h"
#import "MGSAnnotationInfoTemplateDelegate.h"

@interface MGSLayer ()
@property (nonatomic, strong) NSMutableArray *mutableAnnotations;

- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation;
@end

@implementation MGSLayer
@dynamic annotations;
@dynamic hasGraphicsLayer;

- (id)init
{
    return [self initWithName:nil];
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        self.name = name;
        self.mutableAnnotations = [NSMutableArray array];
    }
    
    return self;
}

- (void)setAnnotations:(NSArray *)annotations
{
    if (self.annotations)
    {
        [self deleteAllAnnotations];
    }
    
    [self addAnnotations:annotations];
}

- (NSArray*)annotations
{
    NSMutableArray *extAnnotations = [NSMutableArray array];
    for (MGSLayerAnnotation *annotation in self.mutableAnnotations)
    {
        [extAnnotations addObject:annotation.annotation];
    }
    
    return extAnnotations;
}

#pragma mark - Public Methods
- (void)addAnnotation:(id<MGSAnnotation>)annotation
{
    [self addAnnotations:@[annotation]];
}

- (void)addAnnotations:(NSArray*)annotations
{
    NSMutableArray *newAnnotations = [NSMutableArray arrayWithArray:annotations];
    [newAnnotations removeObjectsInArray:self.annotations];
    
    if ([newAnnotations count])
    {
        [self willAddAnnotations:newAnnotations];
        
        // Sort the add order of the annotations so they are added
        // top to bottom (prevents higher markers from being overlayed
        // on top of lower ones) and left to right
        NSArray *sortedAnnotations = [newAnnotations sortedArrayUsingComparator:^NSComparisonResult(id<MGSAnnotation> obj1, id<MGSAnnotation> obj2) {
            CLLocationCoordinate2D point1 = obj1.coordinate;
            CLLocationCoordinate2D point2 = obj2.coordinate;
            
            if (point1.latitude > point2.latitude)
            {
                return NSOrderedAscending;
            }
            else if (point1.latitude < point2.latitude)
            {
                return NSOrderedDescending;
            }
            else if (point1.longitude > point2.longitude)
            {
                return NSOrderedDescending;
            }
            else if (point1.longitude < point2.longitude)
            {
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }];
        
        for (id<MGSAnnotation> annotation in sortedAnnotations)
        {
            AGSGraphic *graphic = AGSGraphicFromAnnotation(annotation, MGSGraphicDefault, self.markerTemplate);
            MGSLayerAnnotation *mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                                       graphic:graphic];
            
            [graphic.attributes setObject:mapAnnotation
                                   forKey:MGSAnnotationAttributeKey];
            
            [self.mutableAnnotations addObject:mapAnnotation];
            [self.graphicsLayer addGraphic:graphic];
        }
        
        [self didAddAnnotations:newAnnotations];
    }
}

- (void)deleteAnnotation:(id<MGSAnnotation>)annotation
{
    if (annotation && [self.mutableAnnotations containsObject:annotation])
    {
        if ([self.mapView isPresentingCalloutForAnnotation:annotation])
        {
            [self.mapView hideCallout];
        }
        
        MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
        [self.graphicsLayer removeGraphic:layerAnnotation.graphic];
        [self.mutableAnnotations removeObject:layerAnnotation];
    }
}

- (void)deleteAnnotations:(NSArray*)annotations
{
    if ([annotations count])
    {
        [self willRemoveAnnotations:annotations];
        
        for (id<MGSAnnotation> annotation in annotations)
        {
            MGSLayerAnnotation *mapAnnotation = [self layerAnnotationForAnnotation:annotation];
            
            [self.graphicsLayer removeGraphic:mapAnnotation.graphic];
            [mapAnnotation.graphic.attributes removeObjectForKey:MGSAnnotationAttributeKey];
            [self.mutableAnnotations removeObject:mapAnnotation];
        }
        
        [self didRemoveAnnotations:annotations];
    }
}

- (void)deleteAllAnnotations
{
    [self deleteAnnotations:self.annotations];
}

#pragma mark - Class Extension methods
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation
{
    __block void *layerAnnotation = nil;
    [self.mutableAnnotations enumerateObjectsWithOptions:NSEnumerationConcurrent
                                              usingBlock:^(MGSLayerAnnotation *obj, NSUInteger idx, BOOL *stop) {
                                                  if ([obj.annotation isEqual:annotation])
                                                  {
                                                      (*stop) = YES;
                                                      OSAtomicCompareAndSwapPtrBarrier(nil, (__bridge void *)(obj), &layerAnnotation);
                                                  }
                                              }];
    
    return (__bridge MGSLayerAnnotation*)layerAnnotation;
}

#pragma mark - ArcGIS Methods
- (AGSGraphicsLayer*)graphicsLayer
{
    if (_graphicsLayer == nil)
    {
        [self loadGraphicsLayer];
    }
    
    return _graphicsLayer;
}

- (void)loadGraphicsLayer
{
    AGSGraphicsLayer *graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    
    for (MGSLayerAnnotation *annotation in self.mutableAnnotations)
    {
        AGSGraphic *graphic = nil;
        
        if (annotation.graphic)
        {
            graphic = annotation.graphic;
        }
        else
        {
            graphic = AGSGraphicFromAnnotation(annotation.annotation, MGSGraphicDefault, self.markerTemplate);
            [graphic.attributes setObject:annotation
                                   forKey:MGSAnnotationAttributeKey];
            annotation.graphic = graphic;
        }
        
        [graphicsLayer addGraphic:graphic];
    }
    
    [self setGraphicsLayer:graphicsLayer];
}

- (BOOL)hasGraphicsLayer
{
    return (_graphicsLayer != nil);
}

- (void)refreshLayer
{
    AGSSpatialReference *graphicsReference = self.graphicsLayer.spatialReference;
    AGSSpatialReference *viewReference = self.graphicsView.mapView.spatialReference;
    BOOL referencesEqual = [graphicsReference isEqualToSpatialReference:viewReference];
    
    if (graphicsReference && viewReference && (referencesEqual == NO))
    {
        DDLogVerbose(@"Converting %@ to %@", graphicsReference, viewReference);
        
        for (AGSGraphic *graphic in self.graphicsLayer.graphics)
        {
            // Only reproject on a spatial reference mismatch
            if ([graphic.geometry.spatialReference isEqualToSpatialReference:viewReference] == NO)
            {
                graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                           toSpatialReference:viewReference];
            }
        }
    }

    [self.graphicsLayer dataChanged];
}

- (void)setHidden:(BOOL)hidden
{
    if (_hidden != hidden)
    {
        _hidden = hidden;
        self.graphicsView.hidden = hidden;
    }
}

- (MKCoordinateRegion)regionForAnnotations:(NSSet*)annotations
{
    NSMutableArray *latitudeCoordinates = [NSMutableArray array];
    NSMutableArray *longitudeCoordinates = [NSMutableArray array];
    NSArray *allAnnotations = self.annotations;
    
    for (id<MGSAnnotation> annotation in annotations)
    {
        if ([allAnnotations containsObject:annotation])
        {
            CLLocationCoordinate2D coord = annotation.coordinate;
            [latitudeCoordinates addObject:[NSNumber numberWithDouble:coord.latitude]];
            [longitudeCoordinates addObject:[NSNumber numberWithDouble:coord.longitude]];
        }
    }
    
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"doubleValue"
                                                               ascending:YES]];
    NSArray *sortedLat = [latitudeCoordinates sortedArrayUsingDescriptors:sortDescriptors];
    NSArray *sortedLon = [longitudeCoordinates sortedArrayUsingDescriptors:sortDescriptors];
    
    CLLocationDegrees minLat = [[sortedLat objectAtIndex:0] doubleValue];
    CLLocationDegrees maxLat = [[sortedLat lastObject] doubleValue];
    CLLocationDegrees minLon = [[sortedLon objectAtIndex:0] doubleValue];
    CLLocationDegrees maxLon = [[sortedLon lastObject] doubleValue];
    
    MKCoordinateSpan span = MKCoordinateSpanMake((maxLat - minLat), (maxLon - minLon));
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(minLat + ((maxLat - minLat) / 2.0), minLon + ((maxLon - minLon) / 2.0));
    return MKCoordinateRegionMake(center, span);
}

#pragma mark - Map Layer Delegation
- (void)willMoveToMapView:(MGSMapView*)mapView
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)])
    {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)didMoveToMapView:(MGSMapView*)mapView
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willMoveToMapView:)])
    {
        [self.delegate mapLayer:self
              willMoveToMapView:mapView];
    }
}

- (void)willAddAnnotations:(NSArray*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willAddAnnotations:)])
    {
        [self.delegate mapLayer:self
             willAddAnnotations:annotations];
    }
}

- (void)didAddAnnotations:(NSArray*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didAddAnnotations:)])
    {
        [self.delegate mapLayer:self
              didAddAnnotations:annotations];
    }
}

- (void)willRemoveAnnotations:(NSArray*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willRemoveAnnotations:)])
    {
        [self.delegate mapLayer:self
          willRemoveAnnotations:annotations];
    }
}

- (void)didRemoveAnnotations:(NSArray*)annotations
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didRemoveAnnotations:)])
    {
        [self.delegate mapLayer:self
           didRemoveAnnotations:annotations];
    }
}

- (void)willReloadMapLayer
{
    if ([self.delegate respondsToSelector:@selector(willReloadMapLayer:)])
    {
        [self.delegate willReloadMapLayer:self];
    }
}

- (BOOL)shouldDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:shouldDisplayCalloutForAnnotation:)])
    {
        return [self.delegate mapLayer:self
            shouldDisplayCalloutForAnnotation:annotation];
    }
    
    return YES;
}

- (void)willDisplayCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:willDisplayCalloutForAnnotation:)])
    {
        [self.delegate mapLayer:self
            willDisplayCalloutForAnnotation:annotation];
    }
}

- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:calloutViewForAnnotation:)])
    {
        return [self.delegate mapLayer:self
              calloutViewForAnnotation:annotation];
    }
    
    return nil;
}

- (void)calloutAccessoryDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:calloutAccessoryDidReceiveTapForAnnotation:)])
    {
        [self.delegate mapLayer:self
            calloutAccessoryDidReceiveTapForAnnotation:annotation];
    }
}

- (void)didPresentCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:didPresentCalloutForAnnotation:)])
    {
        [self.delegate mapLayer:self
            didPresentCalloutForAnnotation:annotation];
    }
}

@end
