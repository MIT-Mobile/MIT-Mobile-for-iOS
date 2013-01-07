#import <CoreLocation/CoreLocation.h>

#import "MITMapView.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSAnnotation.h"
#import "MITAnnotationAdaptor.h"
#import "MGSRouteLayer.h"
#import "CoreLocation+MITAdditions.h"

@interface MITMapView () <MGSMapViewDelegate,MGSLayerDelegate>
@property (nonatomic, weak) MGSMapView *mapView;
@property (nonatomic, weak) id<MKAnnotation> currentAnnotation;

@property (nonatomic, strong) MGSLayer *annotationLayer;

@property (nonatomic, strong) NSArray *annotationCache;
@property (nonatomic, strong) NSMutableArray *legacyRoutes;
@property (nonatomic, strong) NSMutableArray *routeLayers;

- (void)refreshLayers;
@end

@implementation MITMapView
@dynamic centerCoordinate;
@dynamic region;
@dynamic scrollEnabled;
@dynamic showsUserLocation;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        MGSMapView *mapView = [[MGSMapView alloc] initWithFrame:self.bounds];
        mapView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleWidth);
        mapView.mapViewDelegate = self;

        self.mapView = mapView;
        [self addSubview:mapView];
        
        self.annotationLayer = [[MGSLayer alloc] init];
        self.annotationLayer.delegate = self;
        [self.mapView addLayer:self.annotationLayer
                withIdentifier:@"edu.mit.mobile.map.annotations"];
        
        self.legacyRoutes = [NSMutableArray array];
        self.routeLayers = [NSMutableArray array];
        
        [self setNeedsLayout];
    }
    
    return self;
}

- (void)layoutSubviews
{
    self.mapView.frame = self.bounds;
}

- (void)refreshLayers
{
    [self.annotationLayer refreshLayer];
    for (MGSLayer *layer in self.routeLayers)
    {
        [layer refreshLayer];
    }
}

#pragma mark - Dynamic Properties
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord
{
    [self setCenterCoordinate:coord
                     animated:NO];
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord animated:(BOOL)animated
{
    [self.mapView centerAtCoordinate:coord
                            animated:animated];
}

- (MKCoordinateRegion)region
{
    return self.mapView.mapRegion;
}

- (void)setRegion:(MKCoordinateRegion)region
{
    self.mapView.mapRegion = region;
}

- (BOOL)scrollEnabled
{
    // Always NO
    // Zoom & Pan disable not currently supported by ArcGIS SDK
    return NO;
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    // NOP
    // Zoom & Pan disable not currently supported by ArcGIS SDK
}

- (BOOL)showsUserLocation
{
    return self.mapView.showUserLocation;
}

- (void)setShowsUserLocation:(BOOL)showsUserLocation
{
    self.mapView.showUserLocation = showsUserLocation;
}

#pragma mark - MKMapView Forwarding Stubs
- (CGPoint)convertCoordinate:(CLLocationCoordinate2D)coordinate toPointToView:(UIView *)view
{
    CGPoint screenPoint = [self.mapView screenPointForCoordinate:coordinate];
    
    return [view convertPoint:screenPoint
                     fromView:nil];
}

- (void)fixateOnCampus
{
    // TODO: Implement
    return;
}

#pragma mark - MITMapView Annotation Handling
- (void)refreshCallout
{
    // TODO Implement
    return;
}

- (MKCoordinateRegion)regionForAnnotations:(NSArray *)annotations
{
    NSMutableSet *regionAnnotations = [NSMutableSet set];
    for (MITAnnotationAdaptor *adaptor in self.annotationLayer.annotations)
    {
        if ([annotations containsObject:adaptor.mkAnnotation])
        {
            [regionAnnotations addObject:adaptor];
        }
    }
    
    return [MGSLayer regionForAnnotations:regionAnnotations];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation
{
    [self selectAnnotation:annotation
                  animated:NO
              withRecenter:YES];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation
                animated:(BOOL)animated
            withRecenter:(BOOL)recenter
{
    __block id<MGSAnnotation> mapAnnotation = nil;
    
    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(id<MGSAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MITAnnotationAdaptor class]])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)obj;
            if ([adaptor.mkAnnotation isEqual:annotation])
            {
                mapAnnotation = obj;
                (*stop) = YES;
            }
        }
    }];
    
    if (mapAnnotation)
    {
        if (recenter)
        {
            [self.mapView centerAtCoordinate:mapAnnotation.coordinate];
        }
        
        [self.mapView showCalloutForAnnotation:mapAnnotation];
        self.currentAnnotation = annotation;


        if ([self.delegate respondsToSelector:@selector(mapView:annotationSelected:)])
        {
            [self.delegate mapView:self
                annotationSelected:self.currentAnnotation];
        }
    }
}

- (void)deselectAnnotation:(id<MKAnnotation>)annotation
                  animated:(BOOL)animated
{
    if ([self.currentAnnotation isEqual:annotation])
    {
        [self.mapView hideCallout];
        self.currentAnnotation = nil;
    }
}

- (void)addAnnotation:(id<MKAnnotation>)anAnnotation
{
    [self addAnnotations:@[anAnnotation]];
}

- (void)addAnnotations:(NSArray *)annotations
{
    NSMutableArray *newAnnotations = [NSMutableArray arrayWithArray:annotations];
    for (id<MGSAnnotation> annotation in self.annotationLayer.annotations)
    {
        if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
            [newAnnotations removeObject:adaptor.mkAnnotation];
        }
    }
    
    NSMutableArray *addedAnnotations = [NSMutableArray array];
    for (id<MKAnnotation> mkAnnotation in newAnnotations)
    {
        MITAnnotationAdaptor *adaptor = [[MITAnnotationAdaptor alloc] initWithMKAnnotation:mkAnnotation];
        
        if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)])
        {
            adaptor.legacyAnnotationView = [self.delegate mapView:self
                                                viewForAnnotation:mkAnnotation];
        }
        
        [addedAnnotations addObject:adaptor];
    }
    
    [self.annotationLayer addAnnotations:addedAnnotations];
    [self.annotationLayer refreshLayer];
    
    self.annotationCache = nil;
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation
{
    [self removeAnnotations:@[annotation]];
}

- (void)removeAnnotations:(NSArray *)annotations
{
    if ([annotations count] == 0)
    {
        return;
    }
    
    NSMutableArray *mgsAnnotations = [NSMutableArray array];
    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(id<MGSAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MITAnnotationAdaptor class]])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)obj;
            if ([annotations containsObject:adaptor.mkAnnotation])
            {
                [mgsAnnotations addObject:adaptor];
            }
        }
    }];
    
    [self.annotationLayer deleteAnnotations:mgsAnnotations];
    self.annotationCache = nil;
}

- (void)removeAllAnnotations:(BOOL)includeUserLocation
{
    [self.annotationLayer deleteAllAnnotations];
    
    if (includeUserLocation)
    {
        self.showsUserLocation = NO;
    }
    
    [self.annotationLayer refreshLayer];
    self.annotationCache = nil;
}

- (NSArray*)annotations
{
    if (self.annotationCache == nil)
    {
        NSMutableArray *mkAnnotations = [NSMutableArray array];
        [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(id<MGSAnnotation> obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MITAnnotationAdaptor class]])
            {
                MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)obj;
                [mkAnnotations addObject:adaptor.mkAnnotation];
            }
        }];
        
        self.annotationCache = mkAnnotations;
    }
    
    return self.annotationCache;
}

#pragma mark - Route Handling
- (NSArray*)routes
{
    return [NSArray arrayWithArray:self.legacyRoutes];
}

- (void)addRoute:(id<MITMapRoute>)route
{
    if ([self.legacyRoutes containsObject:route])
    {
        
        return;
    }
    
    NSMutableArray *pathCoordinates = [NSMutableArray array];
    for (CLLocation *location in [route pathLocations])
    {
        NSValue *locationValue = [NSValue valueWithMKCoordinate:[location coordinate]];
        [pathCoordinates addObject:locationValue];
    }
    
    NSMutableArray *stops = [NSMutableArray array];
    if ([route respondsToSelector:@selector(annotations)])
    {
        for (id<MKAnnotation> annotation in [route annotations])
        {
            MITAnnotationAdaptor *adaptor = [[MITAnnotationAdaptor alloc] initWithMKAnnotation:annotation];
            [stops addObject:adaptor];
        }
    }
    
    NSString *identifier = [NSString stringWithFormat:@"edu.mit.mobile.map.routes.%d",[self.routeLayers count]];
    MGSRouteLayer *layer = [[MGSRouteLayer alloc] initWithName:identifier
                                                     withStops:stops
                                               pathCoordinates:pathCoordinates];
    [self.legacyRoutes addObject:route];
    [self.routeLayers addObject:layer];
    
    [self.mapView addLayer:layer
            withIdentifier:identifier];
    [layer refreshLayer];
}

- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route
{
    if ([route respondsToSelector:@selector(annotations)])
    {
        if ([[route annotations] count])
        {
            return [MGSLayer regionForAnnotations:[NSSet setWithArray:[route annotations]]];
        }
    }
    
    return self.mapView.mapRegion;
}

- (void)removeAllRoutes
{
    NSArray *routes = self.routeLayers;
    self.routeLayers = nil;
    
    [routes enumerateObjectsUsingBlock:^(MGSRouteLayer *layer, NSUInteger idx, BOOL *stop) {
        NSString *identifier = [NSString stringWithFormat:@"edu.mit.mobile.map.routes.%d",idx];
        
        [self.mapView removeLayerWithIdentifier:identifier];
        [self.legacyRoutes removeObjectAtIndex:idx];
    }];
}

- (void)removeRoute:(id<MITMapRoute>) route
{
    if ([self.legacyRoutes containsObject:route])
    {
        [self.legacyRoutes enumerateObjectsUsingBlock:^(id<MITMapRoute> route, NSUInteger idx, BOOL *stop) {
            NSString *identifier = [NSString stringWithFormat:@"edu.mit.mobile.map.routes.%d",idx];
            
            [self.routeLayers removeObjectAtIndex:idx];
            [self.mapView removeLayerWithIdentifier:identifier];
        }];
        
        [self.legacyRoutes removeObject:route];
    }
}

- (void)addTileOverlay
{
    // Do nothing!
    return;
}

- (void)removeTileOverlay
{
    // Do nothing!
    return;
}

- (void)removeAllOverlays
{
    // Do nothing!
    return;
}

#pragma mark - MGSMapView Delegation Methods
- (void)mapView:(MGSMapView *)mapView calloutAccessoryDidReceiveTapForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        if ([self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;

            [self.delegate mapView:self
                    annotationViewCalloutAccessoryTapped:adaptor.legacyAnnotationView];
        }
    }
}

- (void)mapView:(MGSMapView *)mapView willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        if ([self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)])
        {
            
        }
    }
}


#pragma mark - MGSLayer Delegation Methods
- (UIView*)mapLayer:(MGSLayer *)layer calloutViewForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        
    }

    return nil;
}
@end
