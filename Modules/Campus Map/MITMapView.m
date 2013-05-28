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

@property (nonatomic, strong) NSMutableArray *legacyRoutes;
@property (nonatomic, strong) NSMutableArray *routeLayers;

- (void)refreshLayers;
@end

@implementation MITMapView
@dynamic centerCoordinate;
@dynamic region;
@dynamic scrollEnabled;
@dynamic showsUserLocation;
@dynamic stayCenteredOnUserLocation;

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
    
    self.minimumRegionSize = 100.0;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    self.mapView.frame = self.bounds;
}

- (void)refreshLayers
{
    [self.mapView refreshLayers:[NSSet setWithObject:self.annotationLayer]];
}

#pragma mark - Dynamic Properties
- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord
{
    self.mapView.centerCoordinate = coord;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)coord
                   animated:(BOOL)animated
{
    [self.mapView setCenterCoordinate:coord
                             animated:animated];
}

- (MKCoordinateRegion)region
{
    return self.mapView.mapRegion;
}

- (void)setRegion:(MKCoordinateRegion)region
{
    [self mapViewRegionWillChange];
    self.mapView.mapRegion = region;
    [self mapViewRegionDidChange];
}

- (BOOL)scrollEnabled
{
    // Always YES
    // Zoom & Pan disable not currently supported by ArcGIS SDK
    return YES;
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

- (BOOL)stayCenteredOnUserLocation
{
    return self.mapView.trackUserLocation;
}

- (void)setStayCenteredOnUserLocation:(BOOL)stayCenteredOnUserLocation
{
    self.mapView.trackUserLocation = stayCenteredOnUserLocation;
}

- (CGFloat)zoomLevel {
    return (CGFloat)self.mapView.zoomLevel;
}

- (void)setZoomLevel:(CGFloat)zoomLevel {
    self.mapView.zoomLevel = zoomLevel;
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
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
    
    for (id<MKAnnotation> anAnnotation in annotations) {
        CLLocationCoordinate2D coordinate = anAnnotation.coordinate;
		if (coordinate.latitude < minLat) {
			minLat = coordinate.latitude;
		}
		if (coordinate.latitude > maxLat) {
			maxLat = coordinate.latitude;
		}
		if(coordinate.longitude < minLon) {
			minLon = coordinate.longitude;
		}
		if (coordinate.longitude > maxLon) {
			maxLon = coordinate.longitude;
		}
    }
    
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
    
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon;
    
    MKCoordinateRegion minRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(0, 0),
                                                                    self.minimumRegionSize, self.minimumRegionSize);
    
    if (latDelta < minRegion.span.latitudeDelta) {
        latDelta = minRegion.span.latitudeDelta;
    }
    
    if (lonDelta < minRegion.span.longitudeDelta) {
        lonDelta = minRegion.span.longitudeDelta;
    }
    
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    
	return region;
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation
{
    [self selectAnnotation:annotation
                  animated:YES
              withRecenter:YES];
}

- (void)selectAnnotation:(id<MKAnnotation>)annotation
                animated:(BOOL)animated
            withRecenter:(BOOL)recenter
{
    MITAnnotationAdaptor *adaptor = [self adaptorForAnnotation:annotation
                                                        create:NO];
    
    if (adaptor && ([self.currentAnnotation isEqual:annotation] == NO))
    {
        [self.mapView showCalloutForAnnotation:adaptor
                                      animated:animated];
        
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
        [self.mapView dismissCallout];
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
        MITAnnotationAdaptor *adaptor = [self adaptorForAnnotation:mkAnnotation];
        adaptor.mapView = self;
        
        [addedAnnotations addObject:adaptor];
    }
    
    [self.annotationLayer addAnnotationsFromArray:addedAnnotations];
    
    [self refreshLayers];
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
    [self.annotations enumerateObjectsUsingBlock:^(id<MKAnnotation> obj, NSUInteger idx, BOOL *stop) {
        MITAnnotationAdaptor *adaptor = [self adaptorForAnnotation:obj
                                                            create:NO];
        
        if (adaptor) {
            [mgsAnnotations addObject:adaptor];
        }
    }];
    
    [self.annotationLayer deleteAnnotationsFromArray:mgsAnnotations];
}

- (void)removeAllAnnotations:(BOOL)includeUserLocation
{
    [self.annotationLayer deleteAllAnnotations];
    
    if (includeUserLocation)
    {
        self.showsUserLocation = NO;
    }
    
    [self refreshLayers];
}

- (NSArray*)annotations
{
    NSMutableArray *mkAnnotations = [NSMutableArray array];
    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(id<MGSAnnotation> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MITAnnotationAdaptor class]])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)obj;
            [mkAnnotations addObject:adaptor.mkAnnotation];
        }
    }];

    return mkAnnotations;
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
                                                     withStops:[NSOrderedSet orderedSetWithArray:stops]
                                               pathCoordinates:pathCoordinates];
    [self.legacyRoutes addObject:route];
    [self.routeLayers addObject:layer];
    
    [self.mapView insertLayer:layer
                  behindLayer:self.annotationLayer];
    
    [self refreshLayers];
}

- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route
{
    double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
    
    for (CLLocation *aLocation in route.pathLocations) {
        CLLocationCoordinate2D coordinate = aLocation.coordinate;
		if (coordinate.latitude < minLat) {
			minLat = coordinate.latitude;
		}
		if (coordinate.latitude > maxLat) {
			maxLat = coordinate.latitude;
		}
		if(coordinate.longitude < minLon) {
			minLon = coordinate.longitude;
		}
		if (coordinate.longitude > maxLon) {
			maxLon = coordinate.longitude;
		}
    }
    
	CLLocationCoordinate2D center;
	center.latitude = minLat + (maxLat - minLat) / 2;
	center.longitude = minLon + (maxLon - minLon) / 2;
    
	double latDelta = maxLat - minLat;
	double lonDelta = maxLon - minLon;
    
    MKCoordinateRegion minRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(0, 0),
                                                                      self.minimumRegionSize, self.minimumRegionSize);
    
    if (latDelta < minRegion.span.latitudeDelta) {
        latDelta = minRegion.span.latitudeDelta;
    }
    
    if (lonDelta < minRegion.span.longitudeDelta) {
        lonDelta = minRegion.span.longitudeDelta;
    }
    
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    
	return region;
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
- (BOOL)mapView:(MGSMapView *)mapView shouldShowCalloutForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]]) {
        MITAnnotationAdaptor *mgsAnnotation = (MITAnnotationAdaptor*) annotation;
        return mgsAnnotation.calloutAnnotationView.enabled;
    }
    
    return NO;
}

- (void)mapView:(MGSMapView *)mapView
didReceiveTapAtCoordinate:(CLLocationCoordinate2D)coordinate
    screenPoint:(CGPoint)screenPoint
{
    if ([self.delegate respondsToSelector:@selector(mapView:wasTouched:)]) {
        [self.delegate mapView:self
                    wasTouched:screenPoint];
    }
}

- (void)mapView:(MGSMapView *)mapView willShowCalloutForAnnotation:(id <MGSAnnotation>)annotation
{

}

- (void)mapView:(MGSMapView *)mapView calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation {
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;
        
        if (adaptor.calloutAnnotationView) {
            if ([self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)]) {
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
        MITMapAnnotationView *annotationView = adaptor.calloutAnnotationView;
        MITMapAnnotationCalloutView *view = [[MITMapAnnotationCalloutView alloc] initWithAnnotationView:annotationView
                                                                                                mapView:self];
        __weak MITMapView *weakSelf = self;
        view.accessoryActionBlock = ^(id sender) {
            if ([weakSelf.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)]) {
                [weakSelf.delegate mapView:weakSelf
      annotationViewCalloutAccessoryTapped:annotationView];
            }
        };
        
        return view;
    }
    
    return nil;
}

- (void)mapView:(MGSMapView*)mapView userLocationDidUpdate:(CLLocation*)location {
    if ([self.delegate respondsToSelector:@selector(mapView:didUpdateUserLocation:)]) {
        [self.delegate mapView:self
         didUpdateUserLocation:location];
    }
}

- (void)mapView:(MGSMapView*)mapView userLocationUpdateFailedWithError:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(locateUserFailed:)]) {
        [self.delegate locateUserFailed:self];
    }
}

#pragma mark - Delegate Forwarding
- (void)mapViewRegionWillChange {
    if ([self.delegate respondsToSelector:@selector(mapViewRegionWillChange:)]) {
        [self.delegate mapViewRegionWillChange:self];
    }
}

- (void)mapViewRegionDidChange {
    if ([self.delegate respondsToSelector:@selector(mapViewRegionDidChange:)]) {
        [self.delegate mapViewRegionDidChange:self];
    }
}

- (MITAnnotationAdaptor*)adaptorForAnnotation:(id<MKAnnotation>)annotation
{
    return [self adaptorForAnnotation:annotation
                               create:YES];
}

- (MITAnnotationAdaptor*)adaptorForAnnotation:(id<MKAnnotation>)annotation
                                       create:(BOOL)shouldCreate
{
    NSMutableSet *annotations = [NSMutableSet setWithSet:[self.annotationLayer.annotations set]];
    
    for (MGSRouteLayer *routeLayer in self.routeLayers) {
        [annotations unionSet:[routeLayer.stops set]];
    }
    
    __block MITAnnotationAdaptor *adaptor = nil;
    [annotations enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if ([obj isKindOfClass:[MITAnnotationAdaptor class]]) {
            MITAnnotationAdaptor *objAdaptor = (MITAnnotationAdaptor*)obj;
            
            if ([objAdaptor.mkAnnotation isEqual:annotation]) {
                adaptor = objAdaptor;
                (*stop) = YES;
            }
        }
    }];
    
    if (adaptor == nil && shouldCreate) {
        adaptor = [[MITAnnotationAdaptor alloc] initWithMKAnnotation:annotation];
    }
    
    return adaptor;
}

- (MITMapAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation
{
    MITAnnotationAdaptor *adaptor = [self adaptorForAnnotation:annotation
                                                        create:NO];
    
    if (adaptor == nil) {
        return nil;
    }
    
    MITMapAnnotationView *annotationView = nil;
    if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
        annotationView = [self.delegate mapView:self
                            viewForAnnotation:annotation];
    }
    
    if (annotationView == nil) {
        annotationView = [[MITPinAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:@"SimplePin"];
    }
    
    adaptor.calloutAnnotationView = annotationView;
    return annotationView;
}

@end
