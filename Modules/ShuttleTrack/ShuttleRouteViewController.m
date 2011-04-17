#import "ShuttleRouteViewController.h"
#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopCell.h"
#import "ShuttleStopViewController.h"

@interface ShuttleRouteViewController(Private)

-(void) loadRouteMap;

-(void) displayTypeChanged:(id)sender;

-(void) setUrl:(MITModuleURL *)moduleURL;
@end


@implementation ShuttleRouteViewController

@synthesize url;
@synthesize route = _route;
@synthesize tableView = _tableView;
@synthesize routeMapViewController = _routeMapViewController;

- (void)dealloc {
	[_viewTypeButton release];
	
	self.route = nil;
	self.tableView = nil;
	self.view = nil;
	[self setUrl:nil];
	
	//self.routeMapViewController = nil;
	[_routeMapViewController release];
	
	[_smallStopImage release];
	[_smallUpcomingStopImage release];


	[_titleCell release];
	[_loadingCell release];
	[_shuttleStopCell release];
	
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];

	if (_route.stops == nil) {
		[_route getStopsFromCache];
	}
    
    self.title = @"Route";
	
	_viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Map"
													   style:UIBarButtonItemStylePlain 
													  target:self
													  action:@selector(displayTypeChanged:)];
	//_viewTypeButton.enabled = NO;										  
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	_smallStopImage = [[UIImage imageNamed:@"shuttle/shuttle-stop-dot.png"] retain];
	_smallUpcomingStopImage = [[UIImage imageNamed:@"shuttle/shuttle-stop-dot-next.png"] retain];
	
	[self setUrl:[[[MITModuleURL alloc] initWithTag:ShuttleTag] autorelease]];
    [url setPath:[NSString stringWithFormat:@"route-list/%@", self.route.routeID] query:nil];
    
    [_titleCell setRouteInfo:self.route];
	_titleCell.frame = CGRectMake(_titleCell.frame.origin.x, _titleCell.frame.origin.y, _titleCell.frame.size.width, [_titleCell heightForCellWithRoute:self.route]);
    [self.view addSubview:_titleCell];
    self.tableView.frame = CGRectMake(0.0, _titleCell.frame.size.height - 4.0, self.view.frame.size.width, self.view.frame.size.height - _titleCell.frame.size.height + 4.0);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	// RouteMapViewController has its own polling timer
    // So, let it do polling if it's visible.
    if(_mapShowing) {
		[self.routeMapViewController viewWillAppear:animated];
	} else {
        // request up to date route information
        [[ShuttleDataManager sharedDataManager] registerDelegate:self];
        [[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
        
        // poll for stop times every 20 seconds 
        _pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:20
                                                          target:self 
                                                        selector:@selector(requestRoute)
                                                        userInfo:nil 
                                                         repeats:YES] retain];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[url setAsModulePath];
    if(_mapShowing) {
		[self.routeMapViewController viewDidAppear:animated];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	if(_mapShowing) {
		[self.routeMapViewController viewWillDisappear:animated];
	}
	
	if ([_pollingTimer isValid]) {
		[_pollingTimer invalidate];
	}
	[_pollingTimer release];
	_pollingTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    if(_mapShowing) {
		[self.routeMapViewController viewDidDisappear:animated];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return self.route.stops.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize constraintSize = CGSizeMake(280.0f, 2009.0f);
	NSString* cellText = @"A"; // just something to guarantee one line
	UIFont* cellFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
	return labelSize.height + 20.0f;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *StopCellIdentifier = @"StopCell";

	ShuttleStopCell* cell = (ShuttleStopCell*)[tableView dequeueReusableCellWithIdentifier:StopCellIdentifier];
	if (nil == cell) {
		[[NSBundle mainBundle] loadNibNamed:@"ShuttleStopCell" owner:self options:nil];
		cell = _shuttleStopCell;
	}
	
    // Set up the cell...
    ShuttleStop *aStop = nil;
	if(nil != self.route && self.route.stops.count > indexPath.row) {
		aStop = [self.route.stops objectAtIndex:indexPath.row];
	}
	
	[cell setShuttleInfo:aStop];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self pushStopViewControllerWithStop:[self.route.stops objectAtIndex:indexPath.row] 
							  annotation:[self.route.annotations objectAtIndex:indexPath.row] 
								animated:YES];
}

-(void) pushStopViewControllerWithStop:(ShuttleStop *)stop annotation:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated {
	_selectedStopAnnotation = annotation;
	ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	shuttleStopVC.shuttleStop = stop;
	shuttleStopVC.annotation = annotation;
	[self.navigationController pushViewController:shuttleStopVC animated:animated];
	(void)shuttleStopVC.view;
	[shuttleStopVC.mapButton addTarget:self action:@selector(showSelectedStop:) forControlEvents:UIControlEventTouchUpInside];
}
	
	
-(void) showSelectedStop:(id)sender
{
	[self showStop:_selectedStopAnnotation animated:YES];
}	

-(void) showStop:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated {	
	[self.navigationController popToViewController:self animated:animated];
	[self setMapViewMode:YES animated:animated];

	[self.routeMapViewController.mapView selectAnnotation:annotation];
	[self.routeMapViewController.mapView setCenterCoordinate:self.routeMapViewController.mapView.region.center animated:NO];

}

// set the view to either map or list mode
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated {
	if (_mapShowing == showMap) {
		// nothing to change
		return;
	}
	
	
	// flip to the correct view. 
	if (animated) {
		[UIView beginAnimations:@"flip" context:nil];
        UIViewAnimationTransition flipTransition = (showMap) ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft;
		[UIView setAnimationTransition:flipTransition forView:self.view cache:NO];
        [UIView setAnimationDuration:0.5];
	}
	
	if (!showMap) {
		[self.routeMapViewController viewWillDisappear:YES];
		[self.routeMapViewController.view removeFromSuperview];
        [self.routeMapViewController viewDidDisappear:YES];
		[self.view addSubview:self.tableView];	
		self.routeMapViewController = nil;
		_viewTypeButton.title = @"Map";
	} else {
		[self.tableView removeFromSuperview];
		[self loadRouteMap];
		self.routeMapViewController.parentViewController = self;
		[self.routeMapViewController viewWillAppear:YES];
		[self.view addSubview:self.routeMapViewController.view];
        [self.routeMapViewController viewDidAppear:YES];
		_viewTypeButton.title = @"List";
	}
	
	if(animated) {
		[UIView commitAnimations];
	}
	
	_mapShowing = showMap;
}

#pragma mark ShuttleRouteViewController(Private)
-(void) loadRouteMap
{
	if (nil == self.routeMapViewController) {
		_routeMapViewController = [[RouteMapViewController alloc] initWithNibName:@"RouteMapViewController" bundle:nil];
		self.routeMapViewController.route = self.route;
		self.routeMapViewController.view.frame = self.view.frame;
	}
}

- (void)requestRoute {
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
}

#pragma mark User Actions
-(void) displayTypeChanged:(id)sender
{	
	[self setMapViewMode:!_mapShowing animated:YES];
	
	NSString *basePath = _mapShowing ? @"route-map" : @"route-list";
	[url setPath:[NSString stringWithFormat:@"%@/%@", basePath, self.route.routeID] query:nil];
	[url setAsModulePath];
}
	
#pragma mark ShuttleDataManagerDelegate
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	
	if(nil == shuttleRoute)
	{
		if (!_shownError) {
			_shownError = YES;
			
			[MITMobileWebAPI showErrorWithHeader:@"Shuttles"];
			
			if([routeID isEqualToString:self.route.routeID]) {
				self.route.liveStatusFailed = YES;
				[_titleCell setRouteInfo:self.route];
			}
		}		
	} 
	else 
	{
		shuttleRoute.liveStatusFailed = NO;
		if ([routeID isEqualToString:self.route.routeID]) {
			if (!self.route.isRunning && [_pollingTimer isValid]) {
				[_pollingTimer invalidate];
			}
		
			_shownError = NO;
		
			//self.routeInfo = shuttleRoute;
			self.route = shuttleRoute;
				if (self.route.annotations.count <= 0) {
					self.route = shuttleRoute;
				}
			[_titleCell setRouteInfo:self.route];
        
			//_routeLoaded = YES;
			[self.tableView reloadData];
		
			//_viewTypeButton.enabled = YES;
		}	 
	}
	
	if ([routeID isEqualToString:self.routeMapViewController.route.routeID]) {
		if (shuttleRoute) {
			self.routeMapViewController.route = shuttleRoute;
		} else {
			self.routeMapViewController.route.liveStatusFailed = YES;
		}

		[self.routeMapViewController refreshRouteTitleInfo];
	}
}

-(void) setUrl:(MITModuleURL *)moduleURL {
	if(url != moduleURL) {
		[url release];
		url = [moduleURL retain];
	}
}

@end

