#import "ShuttleStopViewController.h"
#import "ShuttleStop.h"
#import "ShuttleRoute.h"
#import "ShuttleSubscriptionManager.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MITModule.h"
#import "ShuttleStopMapAnnotation.h"
#import "ShuttleDataManager.h"
#import "RouteMapViewController.h"
#import "ShuttleRouteViewController.h"

#define NOTIFICATION_MINUTES 5
#define MARGIN 10
#define PADDING 4
#define kHeaderTag 837402

@interface ShuttleStopViewController(Private)

//-(void) loadRouteData;

// load our individual stop full data from an item in the full list of stops
//-(void) loadStopFromStops:(NSArray*) stops;

- (void)requestStop;

-(void) findScheduledSubscriptions;

-(BOOL) hasSubscriptionRequestLoading: (NSIndexPath *)theIndexPath;

-(BOOL) hasSubscription: (NSIndexPath *)theIndexPath;

-(void) removeFromLoadingSubscriptionRequests: (NSIndexPath *)indexPath;

//-(ShuttleRoute *) routeForSection: (NSInteger)section;

@end


@implementation ShuttleStopViewController
@synthesize shuttleStop = _shuttleStop;
@synthesize annotation = _shuttleStopAnnotation;
@synthesize shuttleStopSchedules = _shuttleStopSchedules;
@synthesize subscriptions = _subscriptions;
@synthesize loadingSubscriptionRequests = _loadingSubscriptionRequests;
@synthesize mapButton = _mapButton;

- (void)dealloc 
{
	[url release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	self.shuttleStop = nil;

	self.annotation = nil;
	self.loadingSubscriptionRequests = nil;
	self.shuttleStopSchedules = nil;
	self.subscriptions = nil;
	
	[_timeFormatter release];
	[_tableFooterLabel release];
    
	[_mapButton release];
	[_mapThumbnail release];
	
	// shouldn't [super dealloc] do this?
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	
 	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	_timeFormatter = [[NSDateFormatter alloc] init];
	[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];

	_shuttleStopSchedules = [[NSMutableArray alloc] initWithCapacity:[self.shuttleStop.routeStops count]];
    // make sure selected route is sorted first
	for (ShuttleRouteStop *routeStop in self.shuttleStop.routeStops) {
        NSError *error = nil;
        ShuttleStop *aStop = [ShuttleDataManager stopWithRoute:[routeStop routeID] stopID:[routeStop stopID] error:&error];
        if ([[routeStop routeID] isEqualToString:self.shuttleStop.routeID]) {
            [_shuttleStopSchedules insertObject:aStop atIndex:0];
        } else {
            [_shuttleStopSchedules addObject:aStop];
        }
	}
	
	self.title = NSLocalizedString(@"Shuttle Stop", nil);
	
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 135)] autorelease];
	headerView.backgroundColor = [UIColor clearColor];
	
	int mapBuffer = 15;
	int mapSize = 66;
	
	UIFont* titleFont = [UIFont boldSystemFontOfSize:20];
	int titleWidth = headerView.frame.size.width - mapSize - mapBuffer * 3;
	CGSize titleSize = [self.shuttleStop.title sizeWithFont:titleFont
                                          constrainedToSize:CGSizeMake(titleWidth, 300)
                                              lineBreakMode:UILineBreakModeWordWrap];
    
	UILabel* titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(mapSize + mapBuffer * 2, mapBuffer, titleWidth, titleSize.height)] autorelease];
	titleLabel.text = self.shuttleStop.title;
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textAlignment = UITextAlignmentLeft;
	titleLabel.font = [UIFont boldSystemFontOfSize:20];
	titleLabel.lineBreakMode = UILineBreakModeWordWrap;
	titleLabel.numberOfLines = 0;
	
	[headerView addSubview:titleLabel];
	
	
	// add the map view thumbnail
	_mapThumbnail = [[MITMapView alloc] initWithFrame:CGRectMake(2.0, 2.0, mapSize - 4.0, mapSize - 4.0)];
	_mapThumbnail.delegate = self;
	[_mapThumbnail addAnnotation:self.annotation];
	_mapThumbnail.centerCoordinate = self.annotation.coordinate;
	[_mapThumbnail setRegion:MKCoordinateRegionMake(self.annotation.coordinate, MKCoordinateSpanMake(0.003, 0.003))];
	_mapThumbnail.scrollEnabled = NO;
	_mapThumbnail.userInteractionEnabled = NO;
	_mapThumbnail.layer.cornerRadius = 6.0;

	// add a button on top of the map
	_mapButton = [[UIButton alloc] initWithFrame:CGRectMake(mapBuffer, mapBuffer, mapSize, mapSize)];
    //[_mapButton addTarget:self action:@selector(mapThumbnailPressed:) forControlEvents:UIControlEventTouchUpInside];
	_mapButton.backgroundColor = [UIColor whiteColor];
	_mapButton.layer.cornerRadius = 8.0;
	[_mapButton addSubview:_mapThumbnail];
    
	[headerView addSubview:_mapButton];
	
	UIImageView *alertHeaderIcon = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuttle/shuttle-alert-descriptive.png"]] autorelease];
	CGRect alertHeaderIconFrame = alertHeaderIcon.frame;
	alertHeaderIconFrame.origin = CGPointMake(MARGIN, mapSize + mapBuffer * 2);
	alertHeaderIcon.frame = alertHeaderIconFrame;
	[headerView addSubview:alertHeaderIcon];
	
	UILabel *alertHeaderText = [[[UILabel alloc] 
                                 initWithFrame:CGRectMake(
                                                          alertHeaderIcon.frame.origin.x + alertHeaderIcon.frame.size.width + PADDING, 
                                                          alertHeaderIcon.frame.origin.y,
                                                          headerView.frame.size.width - alertHeaderIcon.frame.size.width - PADDING - 2 * MARGIN, 
                                                          30)] autorelease];
	alertHeaderText.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
	alertHeaderText.lineBreakMode = UILineBreakModeWordWrap;
	alertHeaderText.backgroundColor = [UIColor clearColor];
	alertHeaderText.text = @"Tap the 'Alert Me' icon to be notified 5 minutes before the estimated arrival time.";
	alertHeaderText.numberOfLines = 0;
	alertHeaderText.textColor = CELL_DETAIL_FONT_COLOR;
	[headerView addSubview:alertHeaderText];
	
	[self.tableView setTableHeaderView:headerView];
	
	
	_tableFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
	_tableFooterLabel.font = [UIFont systemFontOfSize:14];
	_tableFooterLabel.textAlignment = UITextAlignmentCenter;
	_tableFooterLabel.backgroundColor = [UIColor clearColor];
	
	[self.tableView setTableFooterView:_tableFooterLabel];
	
	[self.tableView applyStandardColors];
	
	[self requestStop];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSubscriptions) name:ShuttleAlertRemoved object:nil];
	
	url = [[MITModuleURL alloc] initWithTag:ShuttleTag];	 
}

-(void) viewWillDisappear:(BOOL)animated
{
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	
	[_pollingTimer invalidate];
	[_pollingTimer release];
	_pollingTimer = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
	[[ShuttleDataManager sharedDataManager] registerDelegate:self];
	
	// poll for stop times every 20 seconds 
	_pollingTimer = [[NSTimer scheduledTimerWithTimeInterval:20
													  target:self 
													selector:@selector(requestStop)
													userInfo:nil 
													 repeats:YES] retain];
}

-(void) viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	// get the parent, and it it is the ShuttleRouteViewController, we can set the url.
	UIViewController *parentController = (ShuttleRouteViewController *)[[MIT_MobileAppDelegate moduleForTag:ShuttleTag] parentForViewController:self];
	ShuttleRouteViewController *shuttleVC = (ShuttleRouteViewController*) parentController;
	NSString *routeID = shuttleVC.route.routeID;
	NSString *root = [[shuttleVC.url.path componentsSeparatedByString:@"/"] objectAtIndex:0];
	[url setPath:[NSString stringWithFormat:@"%@/%@/%@/stops", root, routeID, self.shuttleStop.stopID] query:nil];
	[url setAsModulePath];
}

-(IBAction) mapThumbnailPressed:(id)sender
{
	
	// push a map view onto the stack
	
	RouteMapViewController* routeMap = [[[RouteMapViewController alloc] initWithNibName:@"RouteMapViewController" bundle:nil] autorelease];
	routeMap.route = [[ShuttleDataManager sharedDataManager].shuttleRoutesByID objectForKey:self.shuttleStop.routeID];
	
	// ensure the view and map view are loaded
	(void)routeMap.view;
	
	//MITMapView* mapView = routeMap.mapView;
	
	[routeMap.mapView selectAnnotation:self.annotation];
	routeMap.mapView.centerCoordinate = self.annotation.coordinate;
	
	[self.navigationController pushViewController:routeMap animated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark ShuttleStopViewController(Private) Methods

-(void)requestStop {
	[[ShuttleDataManager sharedDataManager] requestStop:self.shuttleStop.stopID];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.shuttleStopSchedules.count;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    	
	if (section < self.shuttleStopSchedules.count) 
	{
		// determine the route schedule
		ShuttleStop* schedule = [self.shuttleStopSchedules objectAtIndex:section];
		
        // if nextScheduled is not defined, the first row will be negative
		return (schedule.nextScheduled != 0) ? schedule.predictions.count + 1 : 0;
        
	}
	
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ShuttleStopCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[ShuttlePredictionTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		[cell applyStandardFonts];		
    }
    
    if (indexPath.section < self.shuttleStopSchedules.count) 
	{
		// determine the route schedule
		ShuttleStop* schedule = [self.shuttleStopSchedules objectAtIndex:indexPath.section];
		
		NSDate* date = [schedule dateForPredictionAtIndex:indexPath.row];
		NSTimeInterval timeInterval = [date timeIntervalSinceNow];
		int minutes = timeInterval / 60;
		
		cell.textLabel.text = [_timeFormatter stringFromDate:date];
		
		NSString *minutesText;
		if(minutes == 0) {
			minutesText = @"(now)";
		} else if(minutes == 1) {
			minutesText = @"(1 minute)";
		} else {
			minutesText = [NSString stringWithFormat:@"(%d minutes)", minutes];	
		}
		cell.detailTextLabel.text = minutesText;
        cell.detailTextLabel.textColor = CELL_DETAIL_FONT_COLOR;
		
		cell.accessoryView = nil;
        
        if(minutes > NOTIFICATION_MINUTES) {
            
            if([self hasSubscription:indexPath]) {
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuttle/shuttle-alert-toggle-on.png"]] autorelease];
            } else {
                cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuttle/shuttle-alert-toggle-off.png"]] autorelease];
            }
            
            
            if([self hasSubscriptionRequestLoading:indexPath]) {
                cell.accessoryView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
                [((UIActivityIndicatorView *)cell.accessoryView) startAnimating]; 
            }
        }
	}
	
    return cell;
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	ShuttleStop *stop = [self.shuttleStopSchedules objectAtIndex:section];
	NSString *headerTitle = nil;
	
	if (section < self.shuttleStopSchedules.count) {
		headerTitle = [NSString stringWithFormat:@"%@:", [(ShuttleRouteCache *)[stop.routeStop route] title]];
	} else {
		if(section == 0) {
			headerTitle = @"Loading...";
		} else {
			return nil;
		}
	}
	return [UITableView groupedSectionHeaderWithTitle:headerTitle];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ShuttleStop *schedule = [self.shuttleStopSchedules objectAtIndex:indexPath.section];
    
	NSDate *date = [schedule dateForPredictionAtIndex:indexPath.row];
	NSTimeInterval timeInterval = [date timeIntervalSinceNow];
	int minutes = timeInterval / 60;
    
	if(!(minutes > NOTIFICATION_MINUTES)) {
		// shuttle is arriving too soon at this stop to subscribe for a notification
		// just show an alert and exit this handler
		UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:@"Arriving Soon"
                                  message:[NSString stringWithFormat:@"The shuttle is arriving at this stop in %i minutes, leave soon", minutes]
                                  delegate:nil 
                                  cancelButtonTitle:@"OK" 
                                  otherButtonTitles:nil];
		
		[alertView show];
		[alertView release];
		return;
	}
	
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    
    if (types == UIRemoteNotificationTypeNone) {
		// user opted out of notifications for the entire app
		// just show an alert and exit this handler
        
        // Shuttle alerts don't do anything with badges.
		UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:@"Notifications Disabled"
                                  message:@"All notifications for MIT Mobile have been disabled. Quit this application and go to Settings > Notifications to enable them."
                                  delegate:nil 
                                  cancelButtonTitle:@"OK" 
                                  otherButtonTitles:nil];
		
        // TODO: It would be nice if there was some URL we could open to send the user to that settings window.
        
		[alertView show];
		[alertView release];
		return;
    }
    
    if (!(types & UIRemoteNotificationTypeAlert) && !(types & UIRemoteNotificationTypeSound)) {
		// user opted out of the kinds of notifications shuttle makes
		// just show an alert and exit this handler
        
        // Shuttle alerts don't do anything with badges.
		UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:@"Notifications Disabled"
                                  message:@"Alerts and Sounds are required for shuttle alerts. Quit this application and go to Settings > Notifications to enable them."
                                  delegate:nil 
                                  cancelButtonTitle:@"OK" 
                                  otherButtonTitles:nil];
		
        // TODO: It would be nice if there was some URL we could open to send the user to that settings window.
        
		[alertView show];
		[alertView release];
		return;
    }
	
    MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
    MITModule *shuttleModule = [appDelegate moduleForTag:ShuttleTag];
    if (!shuttleModule.pushNotificationEnabled) {
		// user opted out of notifications in Settings module
		// just show an alert and exit this handler
		UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:@"Notifications Disabled"
                                  message:@"Shuttle notifications have been disabled. Go to More > Settings to enable them."
                                  delegate:nil 
                                  cancelButtonTitle:@"OK" 
                                  otherButtonTitles:nil];
		
        // TODO: If settings are disabled in the Settings module, we should add a button in this dialogue to switch the user to the Settings module.
        
		[alertView show];
		[alertView release];
		return;
    }
	
	// do not allow two simulatenous equivalent requests
	if(![self hasSubscriptionRequestLoading:indexPath]) {
		[self.loadingSubscriptionRequests addObject:indexPath];
		
		// reload the table to see the activity indicator start animator
		[self.tableView reloadData];
		
		if(![self hasSubscription:indexPath]) {
			[ShuttleSubscriptionManager 
             subscribeForRoute:schedule.routeID
             atStop:schedule.stopID
             scheduleTime:date
             delegate:self 
             object:indexPath];
		} else {
			[ShuttleSubscriptionManager 
             unsubscribeForRoute:schedule.routeID
             atStop:schedule.stopID
             delegate:self 
             object:indexPath];
		}
	}
	
}

- (void) subscriptionSucceededWithObject: (id)object {
	[self removeFromLoadingSubscriptionRequests:((NSIndexPath *)object)];
	[self findScheduledSubscriptions];
	[self.tableView reloadData];
}		

- (void) subscriptionFailedWithObject: (id)object passkeyError:(BOOL)passkeyError {
	[self removeFromLoadingSubscriptionRequests:((NSIndexPath *)object)];
	if(passkeyError) {
		UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"Subscription failed"
							  message:@"We are sorry, we failed to register your device for a shuttle notification"
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	}
	[self.tableView reloadData];	
}

#pragma mark MITMapViewDelegate
- (MITMapAnnotationView *)mapView:(MITMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MITMapAnnotationView* annotationView = nil;
	
	if ([annotation isKindOfClass:[ShuttleStopMapAnnotation class]]) 
	{
		annotationView = [[[MITMapAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"stop"] autorelease];
        annotationView.image = [UIImage imageNamed:@"shuttle/map_pin_shuttle_stop_complete.png"];
		annotationView.showsCustomCallout = NO;
		annotationView.backgroundColor = [UIColor clearColor];
		annotationView.centeredVertically = YES;
		//annotationView.alreadyOnMap = YES;
		//annotationView.layer.anchorPoint = CGPointMake(0.5, 0.5);
	}
	
	return annotationView;
}

#pragma mark ShuttleDataManagerDelegate
// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes
{
	//[self loadRouteData];
	[self.tableView reloadData];
}

// message sent when a shuttle stop is received. If request fails, this is called with nil 
-(void) stopInfoReceived:(NSArray*)shuttleStopSchedules forStopID:(NSString*)stopID
{
	if(nil == shuttleStopSchedules) {
		// failed to loaded new predictions for shuttleStopSchedules
		// so just do nothing
		return;
	}
	
	NSMutableArray *otherSchedules = [NSMutableArray array];
	self.shuttleStopSchedules = [NSMutableArray array];
	
	if ([self.shuttleStop.stopID isEqualToString:stopID]) 
	{
		// need to make sure the main route is first
		for(ShuttleStop *routeStopSchedule in shuttleStopSchedules) {
			if([routeStopSchedule.routeID isEqualToString:self.shuttleStop.routeID]) {
				self.shuttleStopSchedules = [NSArray arrayWithObject:routeStopSchedule];
			} else {
				[otherSchedules addObject:routeStopSchedule];
			}
		}
        
		self.shuttleStopSchedules = [self.shuttleStopSchedules arrayByAddingObjectsFromArray:otherSchedules];
        
		_tableFooterLabel.text = [NSString stringWithFormat:@"Last updated at %@", [_timeFormatter stringFromDate:[NSDate date]]];
		
		self.loadingSubscriptionRequests = [NSMutableArray array];
		
		[self findScheduledSubscriptions];
		
		[self.tableView reloadData];	
	}
	
}

/*
// do we need this here?
-(void) stopsReceived:(NSArray *)stops
{
	if (nil != stops) {
		[self.tableView reloadData];
	}
    
}
*/

-(void) reloadSubscriptions {
	[self findScheduledSubscriptions];
	[self.tableView reloadData];
}

-(void) findScheduledSubscriptions {
	// determine which schedule stops are subscribed for notifications;		
	self.subscriptions = [NSMutableDictionary dictionary];
    
	for(ShuttleStop *schedule in self.shuttleStopSchedules) {
		//ShuttleRoute *route = [self.routes objectForKey:schedule.routeID];
		
		NSInteger i;
		
		for(i=0; i < [schedule predictionCount]; i++) {
            
			NSDate *prediction = [schedule dateForPredictionAtIndex:i];
			NSString *routeID = schedule.routeID;
			
			if([ShuttleSubscriptionManager hasSubscription:routeID atStop:self.shuttleStop.stopID scheduleTime:prediction]) {
                
				[self.subscriptions setObject:[NSNumber numberWithInt:i] forKey:routeID];
                
				break;
			}
		}
	}
}	

-(BOOL) hasSubscriptionRequestLoading: (NSIndexPath *)theIndexPath {
    
	for(NSIndexPath *aIndexPath in self.loadingSubscriptionRequests) {
        
		if((aIndexPath.section == theIndexPath.section) && (aIndexPath.row == theIndexPath.row)) {
			return YES;
		}
	}
	return NO;
}

-(BOOL) hasSubscription: (NSIndexPath *)indexPath {
	NSString *routeID = ((ShuttleStop *)[self.shuttleStopSchedules objectAtIndex:indexPath.section]).routeID;
	NSNumber *subscriptionIndex = [self.subscriptions objectForKey:routeID];
	if(subscriptionIndex) {
		if([subscriptionIndex intValue] == indexPath.row) {
			return YES;
		}
	}	
	return NO;
}

-(void) removeFromLoadingSubscriptionRequests: (NSIndexPath *)theIndexPath {
	NSInteger index;
	NSIndexPath *aIndexPath;
	for(index=0; index < [self.loadingSubscriptionRequests count]; index++) {
		aIndexPath = [self.loadingSubscriptionRequests objectAtIndex:index];
		if((aIndexPath.section == theIndexPath.section) && (aIndexPath.row == theIndexPath.row)) {
			[self.loadingSubscriptionRequests removeObjectAtIndex:index];
		}
	}
}
@end

@implementation ShuttlePredictionTableViewCell

- (void) layoutSubviews {
	[super layoutSubviews];
	
	CGSize mainLabelSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
	
	CGRect detailFrame = self.textLabel.frame;
	
	// calculate the detail text frame so its bottom is flush with the main text label
	// and its x origin is slightly left of the right edge of the main text
	CGSize detailTextSize = [self.detailTextLabel.text sizeWithFont:self.detailTextLabel.font];
	detailFrame.size = detailTextSize;
	
	// textLabel y-origin is not set correctly so need to calculate it ourselves
	// something funky is going on with the fontSize calculations apple does
	detailFrame.origin.y = round((self.frame.size.height - detailTextSize.height + 1)/2);
	
	// 4 pixel padding
	detailFrame.origin.x = self.textLabel.frame.origin.x + mainLabelSize.width + PADDING;
	self.detailTextLabel.frame = detailFrame;
}

@end
