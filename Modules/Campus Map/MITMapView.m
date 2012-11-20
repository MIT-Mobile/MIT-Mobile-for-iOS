#import "MITMapView.h"
#import "MGSMapCoordinate.h"
#import "MGSMapView.h"
#import "MGSMapLayer.h"
#import "MGSMapAnnotation.h"

@interface MITMapView ()
@property (nonatomic, weak) MGSMapView *mapView;
@property (nonatomic, weak) id<MKAnnotation> currentAnnotation;
@property (nonatomic, strong) MGSMapLayer *annotationLayer;
@property (nonatomic, strong) MGSMapLayer *routeLayer;
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
        self.mapView = mapView;
        [self addSubview:mapView];
        
        self.annotationLayer = [[MGSMapLayer alloc] init];
        [self.mapView addLayer:self.annotationLayer
                withIdentifier:@"edu.mit.mobile.map.annotations"];
        
        self.routeLayer = [[MGSMapLayer alloc] init];
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
    MGSMapCoordinate *coordinate = [[MGSMapCoordinate alloc] initWithLocation:coord];
    [self.mapView centerAtCoordinate:coordinate
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
    MGSMapCoordinate *coord = [[MGSMapCoordinate alloc] initWithLocation:coordinate];
    CGPoint screenPoint = [self.mapView screenPointForCoordinate:coord];
    
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
    return MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
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
    __block MGSMapAnnotation *mapAnnotation = nil;
    
    [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.userData isEqual:annotation])
        {
            mapAnnotation = obj;
            (*stop) = YES;
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
    NSMutableArray *currentAnnotations = [NSMutableArray arrayWithArray:annotations];
    for (MGSMapAnnotation *annotation in self.annotationLayer.annotations)
    {
        if ([currentAnnotations containsObject:annotation.userData])
        {
            [currentAnnotations removeObject:annotation.userData];
        }
    }
    
    for (id<MKAnnotation> annotation in currentAnnotations)
    {
        MGSMapCoordinate *coord = [[MGSMapCoordinate alloc] initWithLocation:[annotation coordinate]];
        MGSMapAnnotation *mapAnnotation = [[MGSMapAnnotation alloc] initWithTitle:[annotation title]
                                                                       detailText:[annotation subtitle]
                                                                     atCoordinate:coord];
        [self.annotationLayer addAnnotation:mapAnnotation];
    }
    
    self.annotationCache = nil;
}

- (void)removeAnnotation:(id<MKAnnotation>)annotation
{
    [self removeAnnotations:@[annotation]];
}

- (void)removeAnnotations:(NSArray *)annotations
{
    for (MGSMapAnnotation *annotation in self.annotationLayer.annotations)
    {
        if ([annotations containsObject:annotation.userData])
        {
            [self.annotationLayer deleteAnnotation:annotation];
        }
    }
    
    self.annotationCache = nil;
}

- (void)removeAllAnnotations:(BOOL)includeUserLocation
{
    [self.annotationLayer deleteAllAnnotations];
    
    if (includeUserLocation)
    {
        self.showsUserLocation = NO;
    }
    
    self.annotationCache = nil;
}

- (NSArray*)annotations
{
    if (self.annotations == nil)
    {
        NSMutableArray *mkAnnotations = [NSMutableArray array];
        [self.annotationLayer.annotations enumerateObjectsUsingBlock:^(MGSMapAnnotation *obj, NSUInteger idx, BOOL *stop) {
            if ([obj.userData conformsToProtocol:@protocol(MKAnnotation)])
            {
                [mkAnnotations addObject:obj.userData];
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
@end
