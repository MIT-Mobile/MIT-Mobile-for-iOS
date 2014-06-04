#import "MITShuttleMapViewController.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MITShuttleMapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *currentLocationButton;
@property (nonatomic, weak) IBOutlet UIButton *exitMapStateButton;
@property (nonatomic) BOOL hasSetUpMapRect;
@property (nonatomic, strong) MKPolyline *routeLineOverlay;

- (IBAction)currentLocationButtonTapped:(id)sender;
- (IBAction)exitMapStateButtonTapped:(id)sender;

@end

@implementation MITShuttleMapViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _route = route;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.hasSetUpMapRect = NO;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    
    self.currentLocationButton.layer.borderWidth = 1;
    self.currentLocationButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.currentLocationButton.layer.cornerRadius = 4;
    self.currentLocationButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    
    self.exitMapStateButton.layer.borderWidth = 1;
    self.exitMapStateButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.exitMapStateButton.layer.cornerRadius = 4;
    self.exitMapStateButton.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    
    [self setState:self.state animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.hasSetUpMapRect) {
        CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(42.357353, -71.095098);
        
        MKMapPoint point = MKMapPointForCoordinate(centerCoordinate);
        [self.mapView setVisibleMapRect:MKMapRectMake(point.x, point.y, 10240.740226, 10240.740226) animated:NO];
        
        [self.mapView setCenterCoordinate:centerCoordinate];
        
        [self setupRouteOverlay];
        
        self.hasSetUpMapRect = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom Accessors

- (void)setState:(MITShuttleMapState)state
{
    [self setState:state animated:YES];
}

- (void)setState:(MITShuttleMapState)state animated:(BOOL)animated
{
    _state = state;
    
    switch (state) {
        case MITShuttleMapStateContracted: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 0;
                self.exitMapStateButton.alpha = 0;
            };
            
            if (animated) {
                [UIView animateWithDuration:0.4 animations:animationBlock];
            } else {
                animationBlock();
            }
            
            break;
        }
        case MITShuttleMapStateExpanded: {
            dispatch_block_t animationBlock = ^{
                self.currentLocationButton.alpha = 1;
                self.exitMapStateButton.alpha = 1;
            };
            
            if (animated) {
                [UIView animateWithDuration:0.5 animations:animationBlock];
            } else {
                animationBlock();
            }
            
            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)currentLocationButtonTapped:(id)sender
{
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
}

- (IBAction)exitMapStateButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shuttleMapViewControllerExitFullscreenButtonPressed:)]) {
        [self.delegate shuttleMapViewControllerExitFullscreenButtonPressed:self];
    }
}

#pragma mark - Private Methods

- (void)setupRouteOverlay
{
    CLLocationCoordinate2D coordinateArray[self.route.stops.count + 1];
    
    for (NSInteger i = 0; i < self.route.stops.count; i++) {
        MITShuttleStop *stop = self.route.stops[i];
        coordinateArray[i] = CLLocationCoordinate2DMake([stop.latitude doubleValue], [stop.longitude doubleValue]);
    }
    
    // Add the first stop as the last point as well, thus closing the line
    MITShuttleStop *firstStop = self.route.stops[0];
    coordinateArray[self.route.stops.count] = CLLocationCoordinate2DMake([firstStop.latitude doubleValue], [firstStop.longitude doubleValue]);
    
    self.routeLineOverlay = [MKPolyline polylineWithCoordinates:coordinateArray count:self.route.stops.count + 1];
    
    [self.mapView addOverlay:self.routeLineOverlay];
}

#pragma mark - MKMapViewDelegate Methods

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isEqual:self.routeLineOverlay]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:self.routeLineOverlay];
        renderer.lineWidth = 2.5;
        renderer.fillColor = [UIColor darkGrayColor];
        renderer.strokeColor = [UIColor darkGrayColor];
        
        return renderer;
    } else {
        return nil;
    }
}

@end
