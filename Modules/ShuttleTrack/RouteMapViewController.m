#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopViewController.h"
#import "ShuttleStop.h"
#import "ShuttleLocation.h"

#define DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) / 180.0 * M_PI)

@interface RouteMapViewController(Private)

// add the shuttles based on self.route.vehicleLocations
-(void) addShuttles;

// remove shuttles that are listed in self.route.vehicleLocations
-(void) removeShuttles;

// update the stop annotations based on the routeInfo
-(void) updateUpcomingStops;

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation;

-(MKCoordinateRegion) regionForRoute;

@end

@implementation RouteMapViewController
@synthesize mapView = _mapView;
@synthesize route = _route;
@synthesize routeInfo = _routeInfo;
@synthesize parentViewController = _MITParentViewController;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void)viewDidLoad {
	
    [super viewDidLoad];

	self.mapView.delegate = self;
	self.mapView.shouldNotDropPins = YES;
	
	_largeStopImage = [[UIImage imageNamed:@"map_pin_shuttle_stop_complete.png"] retain];
	_largeUpcomingStopImage = [[UIImage imageNamed:@"pin_shuttle_stop_complete_next.png"] retain];
	_smallStopImage = [[UIImage imageNamed:@"shuttle-stop-dot.png"] retain];
	_smallUpcomingStopImage = [[UIImage imageNamed:@"shuttle-stop-dot-next.png"] retain];

	//_scrim.frame = CGRectMake(_scrim.frame.origin.x, _scrim.frame.origin.y, _scrim.frame.size.width, 53.0);
	
	[self refreshRouteTitleInfo];
	self.title = NSLocalizedString(@"Route", nil);	

	
	[self.mapView setShowsUserLocation:YES];

	if ([self.route.pathLocations count]) {
		[self.mapView addRoute:self.route];
		self.mapView.region = [self regionForRoute];
	}
	
	// get the extended route info
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																							target:self
																							action:@selector(pollShuttleLocations)] autorelease];

}

-(void)refreshRouteTitleInfo {
	_routeTitleLabel.text = _route.title;
	_routeStatusLabel.text = [_route trackingStatus];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	if ([_pollingTimer isValid]) {
		[_pollingTimer invalidate];
	}
	[_pollingTimer release];
	_pollingTimer = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// make sure its registered. 
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	
	// start polling for new vehicle locations every 10 seconds. 
	_pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:10
													 target:self 
												   selector:@selector(pollShuttleLocations)
												   userInfo:nil 
													 repeats:YES] retain];
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self becomeFirstResponder];

}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)dealloc {
	[_smallStopImage release];
	[_smallUpcomingStopImage release];
	[_largeStopImage release];
	[_largeUpcomingStopImage release];
	_mapView.delegate = nil;
	[_mapView release];
	[_routeStops release];
	[_gpsButton release];
	[_routeTitleLabel release];
	[_routeStatusLabel release];
	[_vehicleAnnotations release];
	
	self.route = nil;
	//self.routeInfo = nil;
	self.parentViewController = nil;
	
	
    [super dealloc];
}

-(void) viewDidUnload
{
	[super viewDidUnload];
}

-(void) setRouteInfo:(ShuttleRoute *) shuttleRoute
{
	[_routeInfo release];
	_routeInfo = [shuttleRoute retain];
	
	[_routeStops release];
	_routeStops = [[NSMutableDictionary dictionaryWithCapacity:shuttleRoute.stops.count] retain];
				   
	for (ShuttleStop* stop in shuttleRoute.stops) {
		[_routeStops setObject:stop forKey:stop.stopID];
	}
	
	// for each of the annotations in our route, retrieve subtitles, which in this case is the next time at stop
	for (ShuttleStopMapAnnotation* annotation in self.route.annotations) 
	{
		ShuttleStop* stop = [_routeStops objectForKey:annotation.shuttleStop.stopID];
		if(nil != stop)
		{
			NSDate* nextScheduled = [NSDate dateWithTimeIntervalSince1970:stop.nextScheduled];
			NSTimeInterval intervalTillStop = [nextScheduled timeIntervalSinceDate:[NSDate date]];
			
			if (intervalTillStop > 0) {
				NSString* subtitle = [NSString stringWithFormat:@"Arriving in %d minutes", (int)(intervalTillStop / 60)];
				[annotation setSubtitle:subtitle];
			}
		}
	}
	
	// tell the map to refresh whatever its current callout is. 
	[_mapView refreshCallout];
}

-(MKCoordinateRegion) regionForRoute
{
	
	// determine the region for the route and zoom to that region
	double minLat = 90;
	double maxLat = -90;
	double minLon = 180;
	double maxLon = -180;
	
	for (CLLocation* location in self.route.pathLocations) {
		CLLocationCoordinate2D coordinate = location.coordinate;
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
	
	MKCoordinateSpan span = MKCoordinateSpanMake(latDelta + latDelta / 4, lonDelta + lonDelta / 4);
	
	MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
	return region;
}

-(void) pollShuttleLocations
{
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
}

-(void) removeShuttles
{
	[_mapView removeAnnotations:_vehicleAnnotations];
	[_vehicleAnnotations release];
	_vehicleAnnotations = nil;
}

-(void) addShuttles
{
	// make a copy since ShuttleRoute's vehicleLocations will be wiped out when it receives new data
	_vehicleAnnotations = [[NSArray arrayWithArray:self.routeInfo.vehicleLocations] retain];
	[_mapView addAnnotations:_vehicleAnnotations];
}

-(void) updateUpcomingStops
{
	for(ShuttleStopMapAnnotation* annotation in _route.annotations) 
	{
		ShuttleStop* info = [_routeStops objectForKey:annotation.shuttleStop.stopID];
		
		if (info.upcoming != annotation.shuttleStop.upcoming) 
		{
			annotation.shuttleStop.upcoming = info.upcoming;
			[self updateStopAnnotation:annotation];
		} 
		
		[self updateStopAnnotation:annotation];
	}
}

-(void) updateStopAnnotation:(ShuttleStopMapAnnotation*)annotation
{
	UIImage* image = nil;
	MITMapAnnotationView* annotationView = [_mapView viewForAnnotation:annotation];		
	
	// determine which image to use for this annotation. If our map is above 2.0, use the big one
	if (_mapView.zoomLevel >= 2.0) {
		image = annotation.shuttleStop.upcoming ? _largeUpcomingStopImage : _largeStopImage;
		annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	else 
	{
		annotationView.layer.anchorPoint = CGPointMake(0.5, 0.5);
		image = annotation.shuttleStop.upcoming ? _smallUpcomingStopImage : _smallStopImage;
	}
	
	UIImageView* imageView = [annotationView.subviews objectAtIndex:0];
	imageView.image = image;
	imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	annotationView.frame = imageView.frame;
	
	[_mapView positionAnnotationView:annotationView];
	
}

#pragma mark User actions
-(IBAction) gpsTouched:(id)sender
{
	
	_mapView.stayCenteredOnUserLocation = !_mapView.stayCenteredOnUserLocation;

	NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];

}

-(IBAction) refreshTouched:(id)sender
{
	//_gpsButton.style = UIBarButtonItemStyleBordered;
	[_gpsButton setBackgroundImage:[UIImage imageNamed:@"scrim-button-background"] forState:UIControlStateNormal];
	_mapView.stayCenteredOnUserLocation = NO;
	
	[_mapView setRegion:[self regionForRoute]];
}


#pragma mark MITMapViewDelegate
- (void)mapViewRegionWillChange:(MITMapView*)mapView
{
	//_gpsButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
}


-(void) mapViewRegionDidChange:(MITMapView*)mapView
{
	NSString *bgImageName = [NSString stringWithFormat:@"scrim-button-background%@.png", _mapView.stayCenteredOnUserLocation ? @"-highlighted" : @""];
	[_gpsButton setBackgroundImage:[UIImage imageNamed:bgImageName] forState:UIControlStateNormal];
	//_gpsButton.style = _mapView.stayCenteredOnUserLocation ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
	
	CGFloat newZoomLevel = mapView.zoomLevel;
	
	if (newZoomLevel != _lastZoomLevel)
	{
		if ((newZoomLevel >= 2.0 && _lastZoomLevel < 2.0 )||
			(newZoomLevel < 2.0 && _lastZoomLevel >= 2.0)) 
		{
			
			for (ShuttleStopMapAnnotation* stop in _route.annotations) 
			{
				[self updateStopAnnotation:stop];
			}
			
		}
	}
	_lastZoomLevel = mapView.zoomLevel;
}

-(void) locateUserFailed
{
	if (_mapView.stayCenteredOnUserLocation) 
	{
		[_gpsButton setBackgroundImage:[UIImage imageNamed:@"scrim-button-background.png"] forState:UIControlStateNormal];
	}	
}

- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
	{
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation] autorelease];
		UIImage* pin = [UIImage imageNamed:@"shuttle-stop-dot.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = YES;
		[annotationView addSubview:imageView];
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.centeredVertically = YES;
		annotationView.alreadyOnMap = YES;
		//annotationView.layer.anchorPoint = CGPointMake(0.5, 0.5);
	}
	else if([annotation isKindOfClass:[ShuttleLocation class]])
	{
		ShuttleLocation* shuttleLocation = (ShuttleLocation*) annotation;
		
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation] autorelease];
		UIImage* pin = [UIImage imageNamed:@"shuttle-bus-location.png"];
		UIImageView* imageView = [[[UIImageView alloc] initWithImage:pin] autorelease];
		
		UIImage* arrow = [UIImage imageNamed:@"shuttle-bus-location-arrow.png"];
		UIImageView* arrowImageView = [[[UIImageView alloc] initWithImage:arrow] autorelease];

		CGAffineTransform cgCTM = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(shuttleLocation.heading));
		arrowImageView.frame = CGRectMake(9, 10, arrowImageView.frame.size.width, arrowImageView.frame.size.height);
		CGFloat verticalAnchor = (arrowImageView.frame.size.height / 2 + 1.5) / arrowImageView.frame.size.height;
		arrowImageView.layer.anchorPoint = CGPointMake(0.5, verticalAnchor);
		arrowImageView.transform = cgCTM;
		
		annotationView.frame = imageView.frame;
		annotationView.canShowCallout = NO;
		[annotationView addSubview:imageView];
		[annotationView addSubview:arrowImageView];
		
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.alreadyOnMap = YES;
		//annotationView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	}
	
	return annotationView;
	
}

- (void)mapView:(MITMapView *)mapView annotationViewcalloutAccessoryTapped:(MITMapAnnotationCalloutView *)view
{
	if ([view.annotation isKindOfClass:[ShuttleStopMapAnnotation class]])
	{
		ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		shuttleStopVC.shuttleStop = [(ShuttleStopMapAnnotation*)view.annotation shuttleStop];
		shuttleStopVC.annotation = (ShuttleStopMapAnnotation*)view.annotation;
		[self.navigationController pushViewController:shuttleStopVC animated:YES];
		[shuttleStopVC.mapButton addTarget:self action:@selector(showSelectedStop:) forControlEvents:UIControlEventTouchUpInside];

	}
}

-(void) showSelectedStop:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

// any touch on the map will invoke this.  
- (void)mapView:(MITMapView *)mapView wasTouched:(UITouch*)touch
{
	
}

-(void) annotationSelected:(id<MKAnnotation>)annotation {
	MITModuleURL *url = ((id<MITModuleURLContainer>)self.parentViewController).url;
	ShuttleStopMapAnnotation *stopAnnotation = (ShuttleStopMapAnnotation *)annotation;
	[url setPath:[NSString stringWithFormat:@"route-map/%@/%@", _route.routeID, stopAnnotation.shuttleStop.stopID] query:nil];
	[url setAsModulePath];
}

-(void) annotationCalloutDidDisappear {
	MITModuleURL *url = ((id<MITModuleURLContainer>)self.parentViewController).url;
	[url setPath:[NSString stringWithFormat:@"route-map/%@", _route.routeID] query:nil];
	[url setAsModulePath];
}
	
#pragma mark ShuttleDataManagerDelegate
// message sent when a shuttle route is received. If request fails, this is called with nil
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	if ([self.route.routeID isEqualToString:routeID])
	{
		if (!self.route.isRunning) {
			[_pollingTimer invalidate];
		}

		[self removeShuttles];
		
		self.routeInfo = shuttleRoute;

		if (![self.mapView.routes count]) {
			[self.mapView addRoute:self.route];
			self.mapView.region = [self regionForRoute];
		}
		
		[self addShuttles];
		[self updateUpcomingStops];
	}
	
}

#pragma mark Shake functionality
- (BOOL)canBecomeFirstResponder {
	return YES;
}


-(void) motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake) {
		[self pollShuttleLocations];
	}
}

@end
