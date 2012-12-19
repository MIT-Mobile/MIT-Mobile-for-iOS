#import <MapKit/MapKit.h>

#import "MITMapView.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSAnnotation.h"
#import "MITAnnotationAdaptor.h"

@interface MITMapView () <MGSMapViewDelegate,MGSLayerDelegate>
@property (nonatomic, weak) MGSMapView *mapView;
@property (nonatomic, weak) id<MKAnnotation> currentAnnotation;
@property (nonatomic, strong) MGSLayer *annotationLayer;
@property (nonatomic, strong) MGSLayer *routeLayer;
@property (nonatomic, strong) NSArray *annotationCache;
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
        
        self.routeLayer = [[MGSLayer alloc] init];
        [self.mapView addLayer:self.routeLayer
                withIdentifier:@"edu.mit.mobile.map.routes"];
        
        [self setNeedsLayout];
    }
    
    return self;
}

- (void)layoutSubviews
{
    self.mapView.frame = self.bounds;
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
        if ([annotations containsObject:adaptor.annotation])
        {
            [regionAnnotations addObject:adaptor];
        }
    }
    
    return [self.annotationLayer regionForAnnotations:regionAnnotations];
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
            if ([adaptor.annotation isEqual:annotation])
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
            [self.mapView centerOnAnnotation:mapAnnotation];
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
            [newAnnotations removeObject:adaptor.annotation];
        }
    }
    
    NSMutableArray *addedAnnotations = [NSMutableArray array];
    for (id<MKAnnotation> mkAnnotation in newAnnotations)
    {
        MITAnnotationAdaptor *adaptor = [[MITAnnotationAdaptor alloc] initWithMKAnnotation:mkAnnotation];
        
        if ([self.delegate respondsToSelector:@selector(mapView:viewForAnnotation:)])
        {
            adaptor.annotationView = [self.delegate mapView:self
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
            if ([annotations containsObject:adaptor.annotation])
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
                [mkAnnotations addObject:adaptor.annotation];
            }
        }];
        
        self.annotationCache = mkAnnotations;
    }
    
    return self.annotationCache;
}

- (NSArray*)routes
{
    return @[];
}

- (void)addRoute:(id<MITMapRoute>)route
{
    // TODO: Implement me!
    return;
}

- (MKCoordinateRegion)regionForRoute:(id<MITMapRoute>)route

{
    // TODO: Implement me!
    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
}

- (void)removeAllRoutes
{
    // TODO: Implement me!
    return;
}

- (void)removeRoute:(id<MITMapRoute>) route
{
    // TODO: Implement me!
    return;
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

/*
// MKMapView-like methods
- (void)mapView:(MITMapView *)mapView didUpdateUserLocation:(CLLocation *)location;

// MKMapViewDelegate forwarding
- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view;
- (void)mapView:(MITMapView *)mapView didAddAnnotationViews:(NSArray *)views;

// any touch on the map will invoke this.
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch;
 */

#pragma mark - MGSMapView Delegation Methods
- (void)mapView:(MGSMapView *)mapView calloutAccessoryDidReceiveTapForAnnotation:(id <MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITAnnotationAdaptor class]])
    {
        if ([self.delegate respondsToSelector:@selector(mapView:annotationViewCalloutAccessoryTapped:)])
        {
            MITAnnotationAdaptor *adaptor = (MITAnnotationAdaptor*)annotation;

            [self.delegate mapView:self
                    annotationViewCalloutAccessoryTapped:adaptor.annotationView];
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
