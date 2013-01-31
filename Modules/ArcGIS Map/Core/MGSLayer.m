#import <ArcGIS/ArcGIS.h>
#import <MapKit/MapKit.h>

#import "MGSLayer.h"
#import "MGSLayerAnnotation.h"

#import "MGSMapView.h"

#import "MGSLayer+Protected.h"
#import "MGSUtility.h"
#import "MGSAnnotationInfoTemplateDelegate.h"
#import "MGSAnnotationSymbol.h"

@interface MGSLayer ()
@property (nonatomic, strong) NSMutableArray *layerAnnotations;
@property (nonatomic, readonly) AGSGraphicsLayer *agsGraphicsLayer;
@end

@implementation MGSLayer
@dynamic annotations;
@dynamic hasGraphicsLayer;

#pragma mark - Class Methods
@dynamic agsGraphicsLayer;

+ (MKCoordinateRegion)regionForAnnotations:(NSSet*)annotations
{
    NSMutableArray *latitudeCoordinates = [NSMutableArray array];
    NSMutableArray *longitudeCoordinates = [NSMutableArray array];
    
    for (id<MGSAnnotation> annotation in annotations)
    {
        CLLocationCoordinate2D coord = annotation.coordinate;
        [latitudeCoordinates addObject:[NSNumber numberWithDouble:coord.latitude]];
        [longitudeCoordinates addObject:[NSNumber numberWithDouble:coord.longitude]];
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
        self.layerAnnotations = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Property Accessor/Mutators
- (void)setMapView:(MGSMapView *)mapView
{
    if ([_mapView isEqual:mapView] == NO)
    {
        [self willMoveToMapView:mapView];
        _mapView = mapView;
        [self didMoveToMapView:mapView];
    }
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
    for (MGSLayerAnnotation *annotation in self.layerAnnotations)
    {
        [extAnnotations addObject:annotation.annotation];
    }
    
    return extAnnotations;
}

- (AGSGraphicsLayer*)agsGraphicsLayer
{
    return _graphicsLayer;
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
            MGSLayerAnnotation *mapAnnotation = nil;
            
            if ([annotation isKindOfClass:[MGSLayerAnnotation class]])
            {
                mapAnnotation = (MGSLayerAnnotation*)annotation;
                
                // Make sure some other layer doesn't already have a claim on this
                // annotation and, if one does, we need to create a new layer annotation
                // which wraps the annotation we are working with
                if ((mapAnnotation.layer != nil) && (mapAnnotation.layer != self))
                {
                    mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:mapAnnotation.annotation
                                                                           graphic:nil];
                }
            }
            
            if (mapAnnotation == nil)
            {
                mapAnnotation = [[MGSLayerAnnotation alloc] initWithAnnotation:annotation
                                                                       graphic:nil];
            }
            
            mapAnnotation.layer = self;
            
            [self.layerAnnotations addObject:mapAnnotation];
        }
        
        [self didAddAnnotations:newAnnotations];
    }
}

- (void)deleteAnnotation:(id<MGSAnnotation>)annotation
{
    if (annotation && [self.layerAnnotations containsObject:annotation])
    {
        if ([self.mapView isPresentingCalloutForAnnotation:annotation])
        {
            [self.mapView hideCallout];
        }
        
        MGSLayerAnnotation *layerAnnotation = [self layerAnnotationForAnnotation:annotation];
        layerAnnotation.layer = nil;
        [self.graphicsLayer removeGraphic:layerAnnotation.graphic];
        [self.layerAnnotations removeObject:layerAnnotation];
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
            
            [self.layerAnnotations removeObject:mapAnnotation];
            [self.graphicsLayer removeGraphic:mapAnnotation.graphic];
            [mapAnnotation.graphic.attributes removeObjectForKey:MGSAnnotationAttributeKey];
        }
        
        [self didRemoveAnnotations:annotations];
    }
}

- (void)deleteAllAnnotations
{
    [self deleteAnnotations:self.annotations];
}

- (void)centerOnAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.annotations containsObject:annotation])
    {
        [self.mapView centerAtCoordinate:annotation.coordinate];
    }
}

- (MKCoordinateRegion)regionForAnnotations
{
    return [MGSLayer regionForAnnotations:[NSSet setWithArray:self.layerAnnotations]];
}

#pragma mark - Class Extension methods
- (MGSLayerAnnotation*)layerAnnotationForAnnotation:(id<MGSAnnotation>)annotation
{
    __block void *layerAnnotation = nil;
    
    // Using OSAtomicCompareAndSwapPtrBarrier so we have atomic pointer
    // assignments since the array is going to be enumerated concurrently
    // and I'd rather not deal with odd race conditions since a standard
    // if-nil-else is not atomic.
    [self.layerAnnotations enumerateObjectsWithOptions:NSEnumerationConcurrent
                                              usingBlock:^(MGSLayerAnnotation *obj, NSUInteger idx, BOOL *stop) {
                                                  if ([obj.annotation isEqual:annotation])
                                                  {
                                                      (*stop) = YES;
                                                      OSAtomicCompareAndSwapPtrBarrier(nil, (__bridge void *)(obj), &layerAnnotation);
                                                  }
                                              }];
    
    return (__bridge MGSLayerAnnotation*)layerAnnotation;
}

// This method should return an AGSGraphic object suitable for
// displaying the given annotation on a map view. The default
// implementation will just return nil. Graphics
// can be pretty messy objects so we'll just leave it to any
// subclasses to implement properly.
- (AGSGraphic*)loadGraphicForAnnotation:(id<MGSAnnotation>)annotation
{
    return nil;
}

// This method should return a MGSAnnotation object which wraps
// the given graphic. This method is called when there exists a
// graphic in the map view which does not already have a matching
// MGSAnnotation object. Generally, this should only be the case
// for server-side map layers. Like the loadGraphicForAnnotation:
// method, the default implementation just returns nil
- (id<MGSAnnotation>)loadAnnotationForGraphic:(AGSGraphic*)graphic
{
    return nil;
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
    [self setGraphicsLayer:graphicsLayer];
}

- (BOOL)hasGraphicsLayer
{
    return (_graphicsLayer != nil);
}

- (void)refreshLayer
{
    if (_graphicsLayer == nil)
    {
        // No graphics layer and we don't want to forcefully
        // create one here so just return.
        return;
    }
    
    [self willReloadMapLayer];
    
    // Create internal annotations for each graphic which already
    // exists in the map layer. The default implementation ignores
    // any pre-existing graphics.
    for (AGSGraphic *graphic in self.agsGraphicsLayer.graphics)
    {
        MGSLayerAnnotation *annotation = [graphic.attributes objectForKey:MGSAnnotationAttributeKey];
        if (annotation == nil)
        {
            id<MGSAnnotation> annotation = [self loadAnnotationForGraphic:graphic];
            if (annotation)
            {
                [self addAnnotation:annotation];
            }
        }
    }
    
    // Sync our current annotations with the graphics. Updating
    // each graphic for possible annotation changes could be a pain in the
    // ass so just brute force it for now; this may need to be
    // optimized in the future.
    NSMutableArray *graphics = [NSMutableArray array];
    for (MGSLayerAnnotation *annotation in self.layerAnnotations)
    {
        if (annotation.graphic)
        {
            [self.graphicsLayer removeGraphic:annotation.graphic];
        }
        
        annotation.graphic = [self loadGraphicForAnnotation:annotation];
        
        if (annotation.graphic == nil)
        {
            annotation.graphic = [AGSGraphic graphicWithGeometry:AGSPointFromCLLocationCoordinate(annotation.coordinate)
                                                          symbol:[[MGSAnnotationSymbol alloc] initWithAnnotation:annotation]
                                                      attributes:[NSMutableDictionary dictionary]
                                            infoTemplateDelegate:[MGSAnnotationInfoTemplateDelegate sharedInfoTemplate]];
        }
        
        [annotation.graphic.attributes setObject:annotation
                                          forKey:MGSAnnotationAttributeKey];
        [graphics addObject:annotation.graphic];
    }
    [self.graphicsLayer addGraphics:graphics];
    
    [self didReloadMapLayer];

    
    // Since a subclass may add graphics in the -didReloadMapLayer method,
    // be sure to go through and re-project everything *after* the delegation
    // call.
    AGSSpatialReference *mapReference = self.graphicsView.mapView.spatialReference;
    
    if (mapReference == nil)
    {
        mapReference = [AGSSpatialReference wgs84SpatialReference];
    }
    
    NSUInteger reprojectionCount = 0;
    for (AGSGraphic *graphic in self.graphicsLayer.graphics)
    {
        DDLogVerbose(@"<%@> sref:\n\tMap: %@\n\tLayer: %@\n\tGraphic: %@",self.name, mapReference, self.graphicsLayer.spatialReference, graphic.geometry.spatialReference);
        // Only reproject on a spatial reference mismatch
        if ([graphic.geometry.spatialReference isEqualToSpatialReference:mapReference] == NO)
        {
            ++reprojectionCount;
            graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:graphic.geometry
                                                                       toSpatialReference:mapReference];
        }
    }
    
    DDLogVerbose(@"\tReprojected %lu graphics", (unsigned long)reprojectionCount);
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

- (void)didReloadMapLayer
{
    if ([self.delegate respondsToSelector:@selector(didReloadMapLayer:)])
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

- (UIView*)calloutViewForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([self.delegate respondsToSelector:@selector(mapLayer:calloutViewForAnnotation:)])
    {
        return [self.delegate mapLayer:self
              calloutViewForAnnotation:annotation];
    }
    
    return nil;
}

@end
