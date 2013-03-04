#import <CoreLocation/CoreLocation.h>
#import "MapKit+MITAdditions.h"

#import "MITMapView.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSAnnotation.h"
#import "MITAnnotationAdaptor.h"
#import "MGSRouteLayer.h"
#import "MITMapAnnotationCalloutView.h"
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

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    MGSMapView *mapView = [[MGSMapView alloc] initWithFrame:self.bounds];
    mapView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                UIViewAutoresizingFlexibleWidth);
    mapView.delegate = self;
    
    self.mapView = mapView;
    [self addSubview:mapView];
    
    self.annotationLayer = [[MGSLayer alloc] initWithName:@"edu.mit.mobile.map.legacy.annotations"];
    self.annotationLayer.delegate = self;
    [self.mapView addLayer:self.annotationLayer];
    
    self.legacyRoutes = [NSMutableArray array];
    self.routeLayers = [NSMutableArray array];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    self.mapView.frame = self.bounds;
}

- (void)refreshLayers
{
    [self.annotationLayer refreshLayer];
    [self.routeLayers enumerateObjectsUsingBlock:^(MGSRouteLayer *layer, NSUInteger idx, BOOL *stop) {
        id<MITMapRoute> route = self.legacyRoutes[idx];
        
        layer.lineColor = [route fillColor];
        layer.lineWidth = [route lineWidth];
    
        [layer refreshLayer];
    }];
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

- (CGFloat)zoomLevel {
	return log(360.0f / self.region.span.longitudeDelta) / log(2.0f) - 1;
}

- (void)setZoomLevel:(CGFloat)zoomLevel {
    CGFloat longitudeDelta = 360.0f / pow(2.0f, zoomLevel + 1);
    CGFloat latitudeDelta = longitudeDelta;
    MKCoordinateRegion region = self.region;
    region.span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    self.region = region;
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
        adaptor.mapView = self;
        
        [addedAnnotations addObject:adaptor];
    }
    
    [self.annotationLayer addAnnotations:addedAnnotations];
    
    [self refreshLayers];
    
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
    
    [self refreshLayers];
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
        NSValue *locationValue = [NSValue valueWithCLLocationCoordinate:[location coordinate]];
        [pathCoordinates addObject:locationValue];
    }
    
    NSMutableArray *stops = [NSMutableArray array];
    if ([route respondsToSelector:@selector(annotations)])
    {
        for (id<MKAnnotation> annotation in [route annotations])
        {
            MITAnnotationAdaptor *adaptor = [[MITAnnotationAdaptor alloc] initWithMKAnnotation:annotation];
            adaptor.mapView = self;
            
            [stops addObject:adaptor];
        }
    }
    
    NSString *identifier = [NSString stringWithFormat:@"edu.mit.mobile.map.routes.%d",[self.routeLayers count]];
    MGSRouteLayer *layer = [[MGSRouteLayer alloc] initWithName:identifier
                                                     withStops:stops
                                               pathCoordinates:pathCoordinates];
    [self.legacyRoutes addObject:route];
    [self.routeLayers addObject:layer];
    
    [self.mapView insertLayer:layer
                  behindLayer:self.annotationLayer];
    
    [self refreshLayers];
}

- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route
{
    NSMutableSet *coordinates = [NSMutableSet set];
    
    for (CLLocation *location in [route pathLocations]) {
        [coordinates addObject:[NSValue valueWithCLLocationCoordinate:location.coordinate]];
    }
    
    if ([route respondsToSelector:@selector(annotations)]) {
        for (id<MKAnnotation> annotation in [route annotations]) {
            [coordinates addObject:[NSValue valueWithCLLocationCoordinate:[annotation coordinate]]];
        }
    }

    return MKCoordinateRegionForCoordinates(coordinates);
}

- (void)removeAllRoutes
{
    NSArray *routes = [NSArray arrayWithArray:self.routeLayers];
    [self.routeLayers removeAllObjects];
    
    [routes enumerateObjectsUsingBlock:^(MGSRouteLayer *layer, NSUInteger idx, BOOL *stop) {
        [self.mapView removeLayer:layer];
        [self.legacyRoutes removeObjectAtIndex:idx];
    }];
}

- (void)removeRoute:(id<MITMapRoute>)aRoute
{
    if ([self.legacyRoutes containsObject:aRoute])
    {
        if ([self.legacyRoutes count] != [self.routeLayers count])
        {
            DDLogError(@"internal inconsistancy error: [%d] != [%d]",[self.legacyRoutes count], [self.routeLayers count]);
            NSAssert(([self.legacyRoutes count] == [self.routeLayers count]),
                     @"internal inconsistancy error, layer count mismatch <%d/%d>",
                     [self.legacyRoutes count], [self.routeLayers count]);
        }
        
        [self.legacyRoutes enumerateObjectsUsingBlock:^(id<MITMapRoute> blockRoute, NSUInteger idx, BOOL *stop) {
            if ([aRoute isEqual:blockRoute]) {
                [self.mapView removeLayer:self.routeLayers[idx]];
                [self.routeLayers removeObjectAtIndex:idx];
                (*stop) = YES;
            }
        }];
        
        [self.legacyRoutes removeObject:aRoute];
        [self refreshLayers];
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
- (void)mapView:(MGSMapView *)mapView willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{

}

- (void)mapView:(MGSMapView *)mapView calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation {
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
        
        if (adaptor.calloutAnnotationView) {
            if ([self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)])
            {
                MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
                [self.delegate mapView:self annotationViewCalloutAccessoryTapped:adaptor.calloutAnnotationView];
            }
        }
    }
}

- (void)mapView:(MGSMapView *)mapView didDismissCalloutForAnnotation:(id<MGSAnnotation>)annotation {
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
        adaptor.calloutAnnotationView = nil;
    }
}

- (UIView*)mapView:(MGSMapView *)mapView calloutViewForAnnotation:(id<MGSAnnotation>)annotation {
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
        MITMapAnnotationView *annotationView = nil;
        
        if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            annotationView = [self.delegate mapView:self
                                  viewForAnnotation:adaptor.mkAnnotation];
        }
        
        
        if (annotationView == nil) {
            annotationView = [[MITPinAnnotationView alloc] initWithAnnotation:adaptor.mkAnnotation
                                                              reuseIdentifier:nil];
        }
        
        adaptor.calloutAnnotationView = annotationView;
        MITMapAnnotationCalloutView *view = [[MITMapAnnotationCalloutView alloc] initWithAnnotationView:annotationView
                                                                                                mapView:self];
        __weak MITMapView *weakSelf = self;
        view.accessoryBlock = ^(id sender) {
            if ([weakSelf.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)]) {
                [weakSelf.delegate mapView:weakSelf
      annotationViewCalloutAccessoryTapped:annotationView];
            }
        };
        
        return view;
    }
    
    return nil;
}
@end
