#import "MITToursMapViewController.h"
#import "MITToursStop.h"
#import "MITToursTiledMapView.h"
#import "MITToursCalloutMapView.h"
#import "MITToursStopAnnotation.h"
#import "MITMapPlaceAnnotationView.h"
#import "MITToursDirectionsToStop.h"
#import "SMCalloutView.h"
#import "SMClassicCalloutView.h"
#import "MITToursCalloutContentView.h"

#define MILES_PER_METER 0.000621371

static NSString * const kMITToursStopAnnotationViewIdentifier = @"MITToursStopAnnotationView";

static NSInteger kAnnotationMarginTop = 0;
static NSInteger kAnnotationMarginBottom = 200;
static NSInteger kAnnotationMarginLeft = 50;
static NSInteger kAnnotationMarginRight = 50;

@interface MITToursMapViewController () <MKMapViewDelegate, SMCalloutViewDelegate, MITToursCalloutContentViewDelegate>

@property (weak, nonatomic) IBOutlet MITToursTiledMapView *tiledMapView;
@property (strong, nonatomic) SMCalloutView *calloutView;
@property (strong, nonatomic) NSMutableArray *dismissingPopoverControllers;
@property (nonatomic) UIEdgeInsets annotationMarginInsets;

@property (nonatomic, strong, readwrite) MITToursTour *tour;

@end

@implementation MITToursMapViewController

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tour = tour;
        self.dismissingPopoverControllers = [[NSMutableArray alloc] init];
        self.annotationMarginInsets = UIEdgeInsetsMake(kAnnotationMarginTop, kAnnotationMarginLeft, kAnnotationMarginBottom, kAnnotationMarginRight);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTiledMapView];
    [self setupCalloutView];
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

- (void)setupCalloutView
{
    SMCalloutDrawnBackgroundView *backgroundView = [[SMCalloutDrawnBackgroundView alloc] initWithFrame:CGRectZero];
    backgroundView.fillBlack = [UIColor whiteColor];
    backgroundView.outerStrokeColor = [UIColor grayColor];
    backgroundView.alpha = 1.0;

    SMCalloutView *calloutView = [[SMCalloutView alloc] initWithFrame:CGRectZero];
    calloutView.contentViewMargin = 0;
    calloutView.delegate = self;
    calloutView.backgroundView = backgroundView;
    calloutView.permittedArrowDirection = SMCalloutArrowDirectionUp;
    calloutView.constrainedInsets = UIEdgeInsetsMake(0, 0, 100, 0); // TODO: Make these accurate
    
    self.calloutView = calloutView;
    
    MITToursCalloutMapView *mapView = (MITToursCalloutMapView *)self.tiledMapView.mapView;
    mapView.calloutView = calloutView;
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

#pragma mark - Custom Callout

- (void)presentCalloutForMapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView
{
    MITToursStop *stop = ((MITToursStopAnnotation *)annotationView.annotation).stop;
    
    MITToursCalloutContentView *contentView = [[MITToursCalloutContentView alloc] initWithFrame:CGRectZero];
    [contentView configureForStop:stop userLocation:mapView.userLocation.location];
    contentView.delegate = self;
    
    SMCalloutView *calloutView = self.calloutView;
    calloutView.contentView = contentView;
    calloutView.calloutOffset = annotationView.calloutOffset;
        
    [calloutView sizeToFit];
    
    [calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.tiledMapView.mapView animated:YES];
}

- (void)dismissCurrentCallout
{
    [self.calloutView dismissCalloutAnimated:YES];
}

#pragma mark - SMCalloutViewDelegate Methods

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset
{
    MKMapView *mapView = self.tiledMapView.mapView;
    CGPoint adjustedCenter = CGPointMake(-offset.width + mapView.bounds.size.width * 0.5,
                                         -offset.height + mapView.bounds.size.height * 0.5);
    CLLocationCoordinate2D newCenter = [mapView convertPoint:adjustedCenter toCoordinateFromView:mapView];
    [mapView setCenterCoordinate:newCenter animated:YES];
    return kSMCalloutViewRepositionDelayForUIScrollView;
}

#pragma mark - MITToursCalloutContentViewDelegate Methods

- (void)calloutWasTappedForStop:(MITToursStop *)stop
{
    // TODO: Transition to stop details
    NSLog( @"Callout view clicked for stop %@", stop.title );
}

@end
