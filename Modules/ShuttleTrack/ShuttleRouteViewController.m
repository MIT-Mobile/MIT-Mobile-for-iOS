#import "ShuttleRouteViewController.h"
#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopCell.h"
#import "ShuttleStopViewController.h"

@interface ShuttleRouteViewController(Private)

-(void) loadRouteMap;

-(void) displayTypeChanged:(id)sender;

@end


@implementation ShuttleRouteViewController

@synthesize route = _route;
@synthesize routeInfo = _routeInfo;
@synthesize tableView = _tableView;
@synthesize routeMapViewController = _routeMapViewController;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)dealloc {
	[_viewTypeButton release];
	
	self.route = nil;
	self.routeInfo = nil;
	self.tableView = nil;
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
    
    self.title = @"Route";
	
	_viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Map"
													   style:UIBarButtonItemStylePlain 
													  target:self
													  action:@selector(displayTypeChanged:)];
	_viewTypeButton.enabled = NO;										  
	self.navigationItem.rightBarButtonItem = _viewTypeButton;
	
	_smallStopImage = [[UIImage imageNamed:@"shuttle-stop-dot.png"] retain];
	_smallUpcomingStopImage = [[UIImage imageNamed:@"shuttle-stop-dot-next.png"] retain];
	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
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

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	if(_mapShowing)
	{
		[self.routeMapViewController viewWillDisappear:animated];
	}
	
	[super viewWillDisappear:animated];
	if ([_pollingTimer isValid]) {
		[_pollingTimer invalidate];
	}
	[_pollingTimer release];
	_pollingTimer = nil;
}


/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    if(!_routeLoaded || _shownError)
		return 1; 
	
	// Info and Stops and phone info
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;

	if(!_routeLoaded || _shownError)
		num =  1;
	else
	{
		
		switch (section) {
			case 0:
				num = 1;
				break;
			case 1:
				num = self.routeInfo.stops.count;
				break;
		}
	}
	
    return num;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

	CGFloat height = 0;
	
    if (indexPath.section == 0) {
		if (!_routeLoaded || _shownError) 
			height = _loadingCell.frame.size.height;
		else
			height = [_titleCell heightForCellWithRoute:self.routeInfo];
	}
	else 
	{
		CGSize constraintSize = CGSizeMake(280.0f, 2009.0f);
		NSString* cellText = @"A"; // just something to guarantee one line
		UIFont* cellFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];	

		CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
		height = labelSize.height + 20.0f;
	}

	return height;
    

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    static NSString *InfoCellIdentifier = @"InfoCell";
    static NSString *StopCellIdentifier = @"StopCell";


	if (indexPath.section == 0) {
		if (!_routeLoaded || _shownError) {
			return _loadingCell;
		}
		
		[_titleCell setRouteInfo:self.routeInfo];
		[_titleCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		return _titleCell;
		
	}

	ShuttleStopCell* cell = (ShuttleStopCell*)[tableView dequeueReusableCellWithIdentifier:StopCellIdentifier];
	if (nil == cell) {
		[[NSBundle mainBundle] loadNibNamed:@"ShuttleStopCell" owner:self options:nil];
		cell = _shuttleStopCell;
	}
	
    // Set up the cell...
    ShuttleStop *aStop = nil;
	if(nil != self.routeInfo && self.routeInfo.stops.count > indexPath.row)
	{
		aStop = [self.routeInfo.stops objectAtIndex:indexPath.row];
	}
	if (nil == aStop) {
		aStop = [self.route.stops objectAtIndex:indexPath.row];
	}
	
	[cell setShuttleInfo:aStop];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {

		
		
		
		_selectedStopAnnotation = [self.route.annotations objectAtIndex:indexPath.row];

		ShuttleStopViewController* shuttleStopVC = [[[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		shuttleStopVC.shuttleStop = [_selectedStopAnnotation shuttleStop];
		shuttleStopVC.annotation = _selectedStopAnnotation;
		shuttleStopVC.route = self.route;
	
		
		[self.navigationController pushViewController:shuttleStopVC animated:YES];
		
		[shuttleStopVC.mapButton addTarget:self action:@selector(showSelectedStop:) forControlEvents:UIControlEventTouchUpInside];
		
		/*
		 [self loadRouteMap];
		 
		// ensure the view and map view are loaded
		self.routeMapViewController.view;
	
		MITMapView* mapView = self.routeMapViewController.mapView;
	
		[mapView selectAnnotation:annotation];
	
		[self.navigationController pushViewController:self.routeMapViewController animated:YES];
		 */
		 
	}
}

-(void) showSelectedStop:(id)sender
{
	[self.navigationController popToViewController:self animated:YES];

	[self displayTypeChanged:_viewTypeButton];
	[_routeMapViewController.mapView selectAnnotation:_selectedStopAnnotation];
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
	// flip to the correct view. 
	[UIView beginAnimations:@"flip" context:nil];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:NO];
	
	if(_mapShowing)
	{
		[self.routeMapViewController viewWillDisappear:YES];
		[self.routeMapViewController.view removeFromSuperview];
		[self.view addSubview:self.tableView];	
		self.tableView.frame = self.view.frame;
		self.routeMapViewController = nil;
		_viewTypeButton.title = @"Map";
	}
	else
	{
		[self.tableView removeFromSuperview];
		[self loadRouteMap];
		self.routeMapViewController.parentsNavController = self.navigationController;
		[self.view addSubview:self.routeMapViewController.view];
		[self.routeMapViewController viewWillAppear:YES];
		_viewTypeButton.title = @"List"; 
	}

	_mapShowing = !_mapShowing;
	
	
	[UIView commitAnimations];

}

#pragma mark ShuttleDataManagerDelegate
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	
	if(nil == shuttleRoute)
	{
		if (!_shownError) {
			_shownError = YES;
			
			UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:nil
															 message:@"Problem loading shuttle info. Please check your internet connection."
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil] autorelease];
			[alert show];
		}
		
	}
	
	else if ([routeID isEqualToString:self.route.routeID]) 
	{
		if (!self.route.isRunning && [_pollingTimer isValid]) {
			[_pollingTimer invalidate];
		}
		
		_shownError = NO;
		
		self.routeInfo = shuttleRoute;
		if (self.route.annotations.count <= 0) {
			self.route = shuttleRoute;
		}
		
		_routeLoaded = YES;
		[self.tableView reloadData];
		
		_viewTypeButton.enabled = YES;
	}
	 
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (!_routeLoaded) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

@end

