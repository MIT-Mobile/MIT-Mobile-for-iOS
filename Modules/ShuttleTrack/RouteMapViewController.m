#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "ShuttleStop.h"
#import "ShuttleLocation.h"
#import "MITMapAnnotationView.h"
#import "UIKit+MITAdditions.h"

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)
#define LARGE_SHUTTLE_ANNOTATION_ZOOM 14.5

@interface RouteMapViewController ()
@property(nonatomic,weak) IBOutlet UILabel* routeTitleLabel;
@property(nonatomic,weak) IBOutlet UILabel* routeStatusLabel;
@property(nonatomic,weak) IBOutlet UIButton* resetButton;
@property(nonatomic,weak) IBOutlet UIButton* gpsButton;
@property(nonatomic,weak) IBOutlet UIImageView* scrim;

@property(nonatomic,strong) NSArray* vehicleAnnotations;
@property(nonatomic,strong) NSDictionary* routeStops;

@property(nonatomic,strong) NSTimer* pollingTimer;

@property(nonatomic) CGFloat lastZoomLevel;
@property(nonatomic) MKMapRect routeRect;

// add the shuttles based on self.route.vehicleLocations
-(void) addShuttles;

// remove shuttles that are listed in self.route.vehicleLocations
-(void) removeShuttles;

// update the stop annotations based on the routeInfo
-(void) updateUpcomingStops;

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation;

@end

@implementation RouteMapViewController
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad {
	
    [super viewDidLoad];
    
    if (self.mapView == nil)
    {
        MITMapView *mapView = [[MITMapView alloc] initWithFrame:self.view.bounds];
        mapView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                    UIViewAutoresizingFlexibleWidth);
        self.mapView = mapView;
        [self.view insertSubview:mapView
                    belowSubview:self.routeInfoView];
    }
    
    [self.scrim setImage:[UIImage imageNamed:@"shuttle/shuttle-secondary-scrim"]];
    [self.resetButton setImage:[UIImage imageNamed:@"shuttle/button-icon-reset-zoom"]
                  forState:UIControlStateNormal];
    
    [self.resetButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                            forState:UIControlStateNormal];
    
    [self.gpsButton setImage:[UIImage imageNamed:@"map/map_button_icon_locate"]
                forState:UIControlStateNormal];
    
    [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                          forState:UIControlStateNormal];

	self.mapView.delegate = self;

	[self refreshRouteTitleInfo];
	self.title = NSLocalizedString(@"Route", nil);	

	if ([self.route.pathLocations count]) {
		[self.mapView addRoute:self.route];
	}
    
    [self narrowRegion];
	
	// get the extended route info
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																							target:self
																							action:@selector(pollShuttleLocations)];

}

-(void)refreshRouteTitleInfo {
	self.routeTitleLabel.text = self.route.title;
	self.routeStatusLabel.text = [self.route trackingStatus];
}

-(void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	self.mapView.showsUserLocation = YES;
    [self.mapView addTileOverlay];

	// make sure its registered. 
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	
	// start polling for new vehicle locations every 10 seconds. 
	self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                         target:self 
                                                       selector:@selector(pollShuttleLocations)
                                                       userInfo:nil 
                                                        repeats:YES];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
    
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
	self.mapView.showsUserLocation = NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
	self.mapView.delegate = nil;
    [self.pollingTimer invalidate];
}

-(void) viewDidUnload
{
	[super viewDidUnload];
}

-(void) setRouteInfo:(ShuttleRoute *) shuttleRoute
{
	NSMutableDictionary *routeStops = [NSMutableDictionary dictionaryWithCapacity:shuttleRoute.stops.count];
	for (ShuttleStop* stop in shuttleRoute.stops) {
		[routeStops setObject:stop
                       forKey:stop.stopID];
	}
    
    _routeInfo = shuttleRoute;
    self.routeStops = routeStops;
    
	// for each of the annotations in our route, retrieve subtitles, which in this case is the next time at stop
	for (ShuttleStopMapAnnotation* annotation in self.route.annotations) 
	{
		ShuttleStop* stop = [self.routeStops objectForKey:annotation.shuttleStop.stopID];
		if(nil != stop) {
			NSDate* nextScheduled = [NSDate dateWithTimeIntervalSince1970:stop.nextScheduled];
			NSTimeInterval intervalTillStop = [nextScheduled timeIntervalSinceDate:[NSDate date]];
			
			if (intervalTillStop > 0) {
				NSString* subtitle = [NSString stringWithFormat:@"Arriving in %d minutes", (int)(intervalTillStop / 60)];
				[annotation setSubtitle:subtitle];
			}
		}
	}
	
	// tell the map to refresh whatever its current callout is. 
	[self.mapView refreshCallout];
}

-(void) pollShuttleLocations
{
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
}

-(void) removeShuttles
{
	[self.mapView removeAnnotations:self.vehicleAnnotations];
	self.vehicleAnnotations = nil;
}

-(void) addShuttles
{
	// make a copy since ShuttleRoute's vehicleLocations will be wiped out when it receives new data
	self.vehicleAnnotations = [NSArray arrayWithArray:self.routeInfo.vehicleLocations];
	[self.mapView addAnnotations:self.vehicleAnnotations];
}

-(void) updateUpcomingStops
{
	for(ShuttleStopMapAnnotation* annotation in self.route.annotations)
	{
		ShuttleStop* info = [self.routeStops objectForKey:annotation.shuttleStop.stopID];
		
		if (info.upcoming != annotation.shuttleStop.upcoming) 
		{
			annotation.shuttleStop.upcoming = info.upcoming;
			[self updateStopAnnotation:annotation];
		}
	}
}

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation
{
    [self.mapView removeAnnotation:annotation];
    [self.mapView addAnnotation:annotation];
    
    return;
}

-(void)narrowRegion {
    
    if ([self.mapView.routes count] && self.route.pathLocations.count > 1) {
        self.mapView.region = [self.mapView regionForRoute:self.route];
        
    } else if (self.route.vehicleLocations.count) {
        self.mapView.region = [self.mapView regionForAnnotations:self.route.vehicleLocations];
        
    } else if (self.route.annotations.count) {
        self.mapView.region = [self.mapView regionForAnnotations:self.route.annotations];
    }
}

-(void)setRouteOverLayBounds:(CLLocationCoordinate2D)center latDelta:(double)latDelta  lonDelta:(double) lonDelta {	
	self.routeRect = MKMapRectMake(center.latitude - latDelta,
                                   center.longitude - lonDelta,
                                   2.0 * latDelta,
                                   2.0 * lonDelta);
}

#pragma mark User actions
-(IBAction) gpsTouched:(id)sender
{
	
	self.mapView.stayCenteredOnUserLocation = !self.mapView.stayCenteredOnUserLocation;
	
    if (self.mapView.stayCenteredOnUserLocation) {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background-highlighted"]
                                  forState:UIControlStateNormal];
    } else {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                                  forState:UIControlStateNormal];
    }
	
	[self.mapView setShowsUserLocation:self.mapView.stayCenteredOnUserLocation];
	
	if (self.mapView.stayCenteredOnUserLocation == NO) {
        [self narrowRegion];
    }

}

-(IBAction) refreshTouched:(id)sender
{
	[self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                              forState:UIControlStateNormal];
	self.mapView.stayCenteredOnUserLocation = NO;
    
    [self narrowRegion];
}


#pragma mark MITMapViewDelegate
- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
    if (self.mapView.stayCenteredOnUserLocation) {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background-highlighted"]
                                  forState:UIControlStateNormal];
    } else {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                                  forState:UIControlStateNormal];
    }
}


-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
    if (self.mapView.stayCenteredOnUserLocation) {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background-highlighted"]
                                  forState:UIControlStateNormal];
    } else {
        [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                                  forState:UIControlStateNormal];
    }
	
	CGFloat newZoomLevel = mapView.zoomLevel;
	
	if ((newZoomLevel < LARGE_SHUTTLE_ANNOTATION_ZOOM) != (self.lastZoomLevel < LARGE_SHUTTLE_ANNOTATION_ZOOM)) {
        for (ShuttleStopMapAnnotation* stop in _route.annotations) {
            [self updateStopAnnotation:stop];
        }
	}
    
	self.lastZoomLevel = newZoomLevel;
}

-(void) locateUserFailed:(MITMapView *)mapView
{
	if (self.mapView.stayCenteredOnUserLocation)
	{
        if (self.mapView.stayCenteredOnUserLocation) {
            [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background-highlighted"]
                                      forState:UIControlStateNormal];
        } else {
            [self.gpsButton setBackgroundImage:[UIImage imageNamed:@"shuttle/scrim-button-background"]
                                      forState:UIControlStateNormal];
        }
	}	
}

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) {
        ShuttleStopMapAnnotation *stopAnnotation = (ShuttleStopMapAnnotation *)annotation;
        
		annotationView = [[MITMapAnnotationView alloc] initWithAnnotation:annotation
                                                           reuseIdentifier:@"stop"];
        
        // determine which image to use for this annotation. If our map is above 2.0, use the big one
        if (self.mapView.zoomLevel >= LARGE_SHUTTLE_ANNOTATION_ZOOM) {
            if (stopAnnotation.shuttleStop.upcoming) {
                annotationView.image = [UIImage imageNamed:@"shuttle/pin_shuttle_stop_complete_next"];
            } else {
                annotationView.image = [UIImage imageNamed:@"shuttle/map_pin_shuttle_stop_complete"];
            }
            
            annotationView.centerOffset = CGPointMake(0,-(annotationView.image.size.height / 2.0));
        } else {
            if (stopAnnotation.shuttleStop.upcoming) {
                annotationView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot-next"];
            } else {
                annotationView.image = [UIImage imageNamed:@"shuttle/shuttle-stop-dot"];
            }
            
            annotationView.calloutOffset = CGPointMake(0,annotationView.image.size.height / 2.0);
        }
        
		annotationView.canShowCallout = NO;
		annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
	}
	else if([annotation isKindOfClass:[ShuttleLocation class]])
	{
		ShuttleLocation* shuttleLocation = (ShuttleLocation*) annotation;
		
		annotationView = [[MITMapAnnotationView alloc] initWithAnnotation:annotation
                                                           reuseIdentifier:@"bus"];
		UIImage* pin = [UIImage imageNamed:@"shuttle/shuttle-bus-location"];
		UIImageView* imageView = [[UIImageView alloc] initWithImage:pin];
		
		UIImage* arrow = [UIImage imageNamed:@"shuttle/shuttle-bus-location-arrow"];
		UIImageView* arrowImageView = [[UIImageView alloc] initWithImage:arrow];

		CGAffineTransform cgCTM = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(shuttleLocation.heading));
		arrowImageView.frame = CGRectMake(9, 10, arrowImageView.frame.size.width, arrowImageView.frame.size.height);
		CGFloat verticalAnchor = (arrowImageView.frame.size.height / 2 + 1.5) / arrowImageView.frame.size.height;
		arrowImageView.layer.anchorPoint = CGPointMake(0.5, verticalAnchor);
		arrowImageView.transform = cgCTM;
		
		[annotationView addSubview:imageView];
		[annotationView addSubview:arrowImageView];
        
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = NO;
        annotationView.showsCustomCallout = NO;
        annotationView.centerOffset = CGPointMake(0, -(pin.size.height / 2.0) + 3.0); // adding 3px because there
                                                                                      // is a 3px transparent border
                                                                                      // around the image.
        
		
		annotationView.backgroundColor = [UIColor clearColor];
		//annotationView.alreadyOnMap = YES;
	}
	
	return annotationView;
	
}

- (void)mapView:(MITMapView *)mapView annotationViewCalloutAccessoryTapped:(MITMapAnnotationView *)view {
    if ([view.annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) {
		ShuttleStopViewController* shuttleStopVC = [[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)view.annotation shuttleStop];
		shuttleStopVC.annotation = (ShuttleStopMapAnnotation*)view.annotation;
        
		[self.navigationController pushViewController:shuttleStopVC
                                             animated:YES];
        
		[shuttleStopVC.mapButton addTarget:self
                                    action:@selector(showSelectedStop:)
                          forControlEvents:UIControlEventTouchUpInside];
	}
}

-(void) showSelectedStop:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ShuttleDataManagerDelegate
// message sent when a shuttle route is received. If request fails, this is called with nil
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	if ([self.route.routeID isEqualToString:routeID])
	{
		if (!self.route.isRunning) {
			[self.pollingTimer invalidate];
		}

		[self removeShuttles];
		
		self.routeInfo = shuttleRoute;
        
        [self.mapView addRoute:self.route];
		//[self narrowRegion];
		
		[self addShuttles];
		[self updateUpcomingStops];
	}
	
}

@end
