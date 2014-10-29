#import "MITToursMapViewController.h"
#import "MITToursStop.h"
#import "MITTiledMapView.h"
#import "MITToursStopAnnotation.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITToursDirectionsToStop.h"
#import "WYPopoverController.h"
#import "MITToursCalloutContentViewController.h"

#define MILES_PER_METER 0.000621371

static NSString * const kMITToursStopAnnotationViewIdentifier = @"MITToursStopAnnotationView";

@interface MITToursMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MITTiledMapView *tiledMapView;
@property (strong, nonatomic) WYPopoverController *calloutPopoverController;
@property (strong, nonatomic) NSMutableArray *dismissingPopoverControllers;

@property (nonatomic, strong, readwrite) MITToursTour *tour;

@end

@implementation MITToursMapViewController

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tour = tour;
        self.dismissingPopoverControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTiledMapView];
    [self configurePopoverAppearance];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupMapBoundingBoxAnimated:YES];
}

- (void)setupTiledMapView
{
    [self.tiledMapView setMapDelegate:self];
    [self.tiledMapView setButtonsHidden:YES animated:NO];
    
    MKMapView *mapView = self.tiledMapView.mapView;
    mapView.showsUserLocation = YES;
    
    // Set up annotations from stops
    NSMutableArray *annotations = [[NSMutableArray alloc] init];
    for (MITToursStop *stop in self.tour.stops) {
        MITToursStopAnnotation *annotation = [[MITToursStopAnnotation alloc] initWithStop:stop];
        [annotations addObject:annotation];
    }
    [mapView addAnnotations:annotations];
    
    [self setupMapRoutes];
}

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    // TODO: This code was more-or-less copied from the dining module map setup. Consider sharing
    // the code to DRY this out.
    MKMapView *mapView = self.tiledMapView.mapView;
    if ([mapView.annotations count] > 0) {
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in mapView.annotations)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        double inset = -zoomRect.size.width * 0.1;
        [mapView setVisibleMapRect:MKMapRectInset(zoomRect, inset, inset) animated:YES];
    } else {
        // TODO: Figure out what the default region should be?
        [mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

- (void)setupMapRoutes
{
    for (MITToursStop *stop in self.tour.stops) {
        MITToursDirectionsToStop *directionsToNextStop = stop.directionsToNextStop;
        NSArray *routePoints = (NSArray *)directionsToNextStop.path;
        CLLocationCoordinate2D segmentPoints[routePoints.count];
        for (NSInteger i = 0; i < routePoints.count; i++) {
            NSArray *point = [routePoints objectAtIndex:i];
            // Convert to location coordinate
            NSNumber *longitude = [point objectAtIndex:0];
            NSNumber *latitude = [point objectAtIndex:1];
            segmentPoints[i] = CLLocationCoordinate2DMake([latitude doubleValue],[longitude doubleValue]);
        }
        MKPolyline *polyline = [MKPolyline polylineWithCoordinates:segmentPoints count:routePoints.count];
        [self.tiledMapView.mapView addOverlay:polyline];
    }
}

#pragma mark - MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (![annotation isKindOfClass:[MITToursStopAnnotation class]]) {
        return nil;
    }
    
    MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITToursStopAnnotationViewIdentifier];
    if (!annotationView) {
        annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITToursStopAnnotationViewIdentifier];
        annotationView.canShowCallout = NO;
    }
    
    MITToursStop *stop = ((MITToursStopAnnotation *)annotation).stop;
    NSInteger number = [self.tour.stops indexOfObject:stop];
    [annotationView setNumber:(number + 1)];
    
    if ([stop.stopType isEqualToString:@"Main Loop"]) {
        annotationView.layer.borderColor = [UIColor clearColor].CGColor;
        annotationView.layer.borderWidth = 0;
    } else {
        annotationView.layer.borderColor = [UIColor blueColor].CGColor;
        annotationView.layer.borderWidth = 2;
    }
    
    return annotationView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.lineWidth = 2.5;
        renderer.fillColor = [UIColor redColor];
        renderer.strokeColor = [UIColor redColor];
        renderer.alpha = 1.0;
        return renderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    [self presentCalloutForMapView:mapView annotationView:view];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [self dismissCurrentCallout];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [self dismissCurrentCallout];
    if (mapView.selectedAnnotations.count) {
        for (id<MKAnnotation> annotation in mapView.selectedAnnotations) {
            [mapView deselectAnnotation:annotation animated:YES];
        }
    }
}


#pragma mark - Custom Callout

- (void)presentCalloutForMapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view
{
    MITToursStopAnnotation *annotation = view.annotation;
    
    MITToursCalloutContentViewController *contentController = [[MITToursCalloutContentViewController alloc] initWithNibName:nil bundle:nil];
    contentController.stopType = annotation.stop.stopType;
    contentController.stopName = annotation.stop.title;
    
    // Get distance for current user location
    CLLocation *userLocation = mapView.userLocation.location;
    if (userLocation) {
        // TODO: DRY this out
        NSArray *stopCoords = annotation.stop.coordinates;
        // Convert to location coordinate
        NSNumber *longitude = [stopCoords objectAtIndex:0];
        NSNumber *latitude = [stopCoords objectAtIndex:1];
        CLLocation *stopLocation = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                              longitude:[longitude doubleValue]];
        double distanceInMeters = [stopLocation distanceFromLocation:userLocation];
        contentController.distanceInMiles = distanceInMeters * MILES_PER_METER;
        contentController.shouldDisplayDistance = YES;
    } else {
        contentController.shouldDisplayDistance = NO;
    }
    
    WYPopoverController *calloutPopover = [[WYPopoverController alloc] initWithContentViewController:contentController];
    // Allow the user to interact with the map annotations even when the popover is displayed
    calloutPopover.passthroughViews = @[self.tiledMapView.mapView];
    [calloutPopover presentPopoverFromRect:view.frame inView:self.tiledMapView.mapView permittedArrowDirections:WYPopoverArrowDirectionUp animated:YES];
    
    [self dismissCurrentCallout];
    self.calloutPopoverController = calloutPopover;
}

- (void)dismissCurrentCallout
{
    WYPopoverController *popover = self.calloutPopoverController;
    if (popover) {
        [self.dismissingPopoverControllers addObject:popover];
        [popover dismissPopoverAnimated:YES completion:^{
            [self.dismissingPopoverControllers removeObject:popover];
        }];
        self.calloutPopoverController = nil;
    }
}

#pragma mark - WYPopover Appearance

- (void)configurePopoverAppearance
{
    [WYPopoverController setDefaultTheme:[WYPopoverTheme theme]];
    WYPopoverBackgroundView *appearance = [WYPopoverBackgroundView appearance];
    [appearance setOuterStrokeColor:[UIColor grayColor]];
    [appearance setViewContentInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    [appearance setFillTopColor:[UIColor whiteColor]];
    [appearance setFillBottomColor:[UIColor whiteColor]];
}

@end
