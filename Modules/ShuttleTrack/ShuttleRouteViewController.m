#import "ShuttleRouteViewController.h"
#import "RouteMapViewController.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleStopCell.h"
#import "ShuttleStopViewController.h"
#import "MITUIConstants.h"

@interface ShuttleRouteViewController()
@property(nonatomic,strong) UIBarButtonItem* viewTypeButton;

@property(nonatomic,strong) IBOutlet UIView *contentView;
@property(nonatomic,strong) IBOutlet RouteInfoTitleCell* titleCell;
@property(nonatomic,strong) IBOutlet UITableViewCell* loadingCell;
@property(nonatomic,strong) IBOutlet ShuttleStopCell* shuttleStopCell;
@property(nonatomic,strong) IBOutlet UITableView* tableView;

@property(nonatomic,strong) NSTimer* pollingTimer;
@property(nonatomic,strong) ShuttleStopMapAnnotation* selectedStopAnnotation;
@property(nonatomic,strong) MITModuleURL* url;

@property(nonatomic,getter=isMapShowing) BOOL mapShowing;
@property(nonatomic,getter=isRouteLoaded) BOOL routeLoaded;
@property(nonatomic,getter=didShowError) BOOL showedError;

- (void)displayTypeChanged:(id)sender;
@end


@implementation ShuttleRouteViewController

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc {
    self.viewTypeButton = nil;
	self.route = nil;
	self.tableView = nil;
	self.url = nil;
    self.titleCell = nil;
    self.loadingCell = nil;
    self.shuttleStopCell = nil;
    self.routeMapViewController = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];

	if (self.route.stops == nil) {
		[self.route getStopsFromCache];
	}
    
    self.title = @"Route";
	
	self.viewTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Map"
                                                           style:UIBarButtonItemStylePlain 
                                                          target:self
                                                          action:@selector(displayTypeChanged:)];
	self.navigationItem.rightBarButtonItem = self.viewTypeButton;
	
    MITModuleURL *url = [[MITModuleURL alloc] initWithTag:ShuttleTag
                                                     path:[NSString stringWithFormat:@"route-list/%@", self.route.routeID]
                                                    query:nil];
    self.url = url;
    
    CGFloat titleCellHeight = [self.titleCell heightForCellWithRoute:self.route];
    CGRect titleFrame = self.titleCell.frame;
    titleFrame.size.height = titleCellHeight;
    
    CGRect tableFrame = self.tableView.frame;
    tableFrame.origin.y = CGRectGetMinY(self.view.bounds) + titleCellHeight - 4.0;
    tableFrame.size.height = CGRectGetHeight(self.view.bounds) - titleCellHeight + 4.0;
    
    self.titleCell.frame = titleFrame;
    self.tableView.frame = tableFrame;
    [self.titleCell setRouteInfo:self.route];
}

- (void)viewDidUnload
{
    [self.routeMapViewController removeFromParentViewController];
	self.routeMapViewController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	// RouteMapViewController has its own polling timer
    // So, let it do polling if it's visible.
    if(!self.isMapShowing) {
        // request up to date route information
        [[ShuttleDataManager sharedDataManager] registerDelegate:self];
        [[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
        
        // poll for stop times every 20 seconds 
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:20
                                                             target:self 
                                                           selector:@selector(requestRoute)
                                                           userInfo:nil 
                                                            repeats:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.url setAsModulePath];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	if ([self.pollingTimer isValid]) {
		[self.pollingTimer invalidate];
	}
    
    self.pollingTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    
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
    return [self.route.stops count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize constraintSize = CGSizeMake(280.0f, 2009.0f);
	NSString* cellText = @"A"; // just something to guarantee one line
	UIFont* cellFont = [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]];
	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
	return labelSize.height + 20.0f;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *StopCellIdentifier = @"StopCell";

	ShuttleStopCell* cell = (ShuttleStopCell*)[tableView dequeueReusableCellWithIdentifier:StopCellIdentifier];
	if (nil == cell) {
		[[NSBundle mainBundle] loadNibNamed:@"ShuttleStopCell"
                                      owner:self
                                    options:nil];
		cell = self.shuttleStopCell;
	}
	
    // Set up the cell...
    ShuttleStop *aStop = nil;
	if(nil != self.route && [self.route.stops count] > indexPath.row) {
		aStop = self.route.stops[indexPath.row];
	}
	
	[cell setShuttleInfo:aStop];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self pushStopViewControllerWithStop:self.route.stops[indexPath.row] 
							  annotation:self.route.annotations[indexPath.row] 
								animated:YES];
}

-(void) pushStopViewControllerWithStop:(ShuttleStop *)stop annotation:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated {
	self.selectedStopAnnotation = annotation;
    
	ShuttleStopViewController* shuttleStopVC = [[ShuttleStopViewController alloc] initWithStyle:UITableViewStyleGrouped];
	shuttleStopVC.shuttleStop = stop;
	shuttleStopVC.annotation = annotation;
	[self.navigationController pushViewController:shuttleStopVC
                                         animated:animated];
    
    /* TODO (bskinner,5/30/2013)
     *  Fix this pattern. We should not be forcing the view
     *  to load here. Maybe add a block or a custom target/action
     *  mutator?
     */
	if (shuttleStopVC.view) {
        [shuttleStopVC.mapButton addTarget:self
                                    action:@selector(showSelectedStop:)
                          forControlEvents:UIControlEventTouchUpInside];
    }
}

	
-(void) showSelectedStop:(id)sender
{
	[self showStop:self.selectedStopAnnotation
          animated:YES];
}	

-(void) showStop:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated {	
	[self.navigationController popToViewController:self animated:animated];
	[self setMapViewMode:YES animated:animated];

	[self.routeMapViewController.mapView selectAnnotation:annotation];
	[self.routeMapViewController.mapView setCenterCoordinate:self.routeMapViewController.mapView.region.center animated:NO];

}

// set the view to either map or list mode
-(void)setMapViewMode:(BOOL)showMap animated:(BOOL)animated {
	if (self.isMapShowing != showMap) {
        if (showMap) {
            if (self.routeMapViewController == nil) {
                RouteMapViewController *routeMapViewController = [[RouteMapViewController alloc] initWithNibName:@"RouteMapViewController"
                                                                                                          bundle:nil];
                routeMapViewController.route = self.route;
                [self addChildViewController:routeMapViewController];
                self.routeMapViewController = routeMapViewController;
            }
            
            self.routeMapViewController.view.frame = self.contentView.bounds;
            [UIView transitionFromView:self.contentView
                                toView:self.routeMapViewController.view
                              duration:(animated ? 0.5 : 0.0)
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            completion:^(BOOL finished) {
                                self.viewTypeButton.title = @"List";
                            }];
            
        } else {
            [UIView transitionFromView:self.routeMapViewController.view
                                toView:self.contentView
                              duration:(animated ? 0.5 : 0.0)
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            completion:^(BOOL finished) {
                                self.viewTypeButton.title = @"Map";
                                
                                [self.routeMapViewController.view removeFromSuperview];
                                [self.routeMapViewController removeFromParentViewController];
                                self.routeMapViewController = nil;
                            }];
            
        }
        
        self.mapShowing = showMap;
    }
}

- (void)requestRoute {
	[[ShuttleDataManager sharedDataManager] requestRoute:self.route.routeID];
}

#pragma mark User Actions
-(void) displayTypeChanged:(id)sender
{	
	[self setMapViewMode:!self.isMapShowing
                animated:YES];
	
	NSString *basePath = self.isMapShowing ? @"route-map" : @"route-list";
	[self.url setPath:[NSString stringWithFormat:@"%@/%@", basePath, self.route.routeID]
                query:nil];
	[self.url setAsModulePath];
}
	
#pragma mark ShuttleDataManagerDelegate
-(void) routeInfoReceived:(ShuttleRoute*)shuttleRoute forRouteID:(NSString*)routeID
{
	
	if(nil == shuttleRoute) {
		if (!self.didShowError) {
			self.showedError = YES;
			
            [UIAlertView alertViewForError:nil
                                 withTitle:@"Shuttles"
                         alertViewDelegate:nil];
			
			if ([routeID isEqualToString:self.route.routeID]) {
				self.route.liveStatusFailed = YES;
				[self.titleCell setRouteInfo:self.route];
			}
		}		
	} else {
		shuttleRoute.liveStatusFailed = NO;
		if ([routeID isEqualToString:self.route.routeID]) {
			if (!self.route.isRunning) {
                if ([self.pollingTimer isValid]) {
                    [self.pollingTimer invalidate];
                }
			}
		
			self.showedError = NO;
		
			self.route = shuttleRoute;
            if ([self.route.annotations count] <= 0) {
                self.route = shuttleRoute;
            }

			[self.titleCell setRouteInfo:self.route];
        
			[self.tableView reloadData];
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

@end

