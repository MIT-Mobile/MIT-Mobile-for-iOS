#import "ShuttleRoutes.h"
#import "ShuttleRouteViewController.h"
#import "RouteMapViewController.h"
#import "SecondaryGroupedTableViewCell.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "UITableView+MITUIAdditions.h"

@implementation ShuttleRoutes

@synthesize shuttleRoutes = _shuttleRoutes;
@synthesize saferideRoutes = _saferideRoutes;
@synthesize nonSaferideRoutes = _nonSaferideRoutes;
@synthesize sections = _sections;
@synthesize isLoading = _isLoading;

- (void)dealloc {
	
	self.shuttleRoutes = nil;
	self.saferideRoutes = nil;
	self.nonSaferideRoutes = nil;
	self.sections = nil;
	
	[_shuttleRunningImage release];
	[_shuttleNotRunningImage release];
	[_contactInfo release];
	
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
        self.title = @"Shuttles";
    }
    return self;
}


- (void)viewDidUnload {
	
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	

}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	_contactInfo = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Parking Office", @"description",
																						 @"16172586510", @"phoneNumber", 
																						 @"(617.258.6510)", @"formattedPhoneNumber", nil, nil],
					 [NSDictionary dictionaryWithObjectsAndKeys:@"Saferide", @"description",
																@"16172532997", @"phoneNumber",
																@"(617.253.2997)", @"formattedPhoneNumber", nil, nil], nil] retain];

	ShuttleDataManager* dataManager = [ShuttleDataManager sharedDataManager];
	[dataManager registerDelegate:self];	
	
	_shuttleRunningImage = [[UIImage imageNamed:@"shuttle.png"] retain];
	_shuttleNotRunningImage = [[UIImage imageNamed:@"shuttle-off.png"] retain];
	
    [self.tableView applyStandardColors];
    
	NSArray* shuttleRoutes = [dataManager shuttleRoutes];
	
	if(nil == self.shuttleRoutes)
	{
		// when setting isLoading, will tell the tableview to show loading cell
		self.isLoading = YES;
		[self.tableView reloadData];
		[dataManager requestRoutes];
	}
	else 
	{
		self.shuttleRoutes = shuttleRoutes;
	}

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshRoutes)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	// if they're going to display, and we're not currently loading and we haven't retrieved any routes, try again
	if (!self.isLoading && self.shuttleRoutes == nil) {
		self.isLoading = YES;
		[self.tableView reloadData];
		[[ShuttleDataManager sharedDataManager] requestRoutes];
	}
}


/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
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

#pragma mark -
#pragma mark Table view delegation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (self.isLoading) {
		return 1;
	}
	
	return self.sections.count;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if (self.isLoading) {
		return 1;
	}
	
	NSArray* routes = [[self.sections objectAtIndex:section] objectForKey:@"routes"];
	if (nil != routes) {
		return routes.count;
	}
	
	NSArray* phoneNumbers = [[self.sections objectAtIndex:section] objectForKey:@"phoneNumbers"];
	if (nil != phoneNumbers) {
		return phoneNumbers.count;
	}

	// one row for "no data found"
	return 1;
	
}

- (UIView *) tableView: (UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString *headerTitle = [[self.sections objectAtIndex:section] objectForKey:@"title"];
	return [UITableView groupedSectionHeaderWithTitle:headerTitle];
}

- (CGFloat)tableView: (UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return GROUPED_SECTION_HEADER_HEIGHT;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
	if (self.isLoading) {
		
		static NSString *loadingCellID = @"LoadingCell";
		UITableViewCell* loadingCell = [tableView dequeueReusableCellWithIdentifier:loadingCellID];
		if(nil == loadingCell)
		{
			loadingCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellID] autorelease];
		
			// create the isLoading Cell
			loadingCell.textLabel.text = @"Loading Routes";
			UIActivityIndicatorView* activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
			[loadingCell.contentView addSubview:activityIndicator];
			activityIndicator.frame = CGRectMake(200, 15, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
			[activityIndicator startAnimating];
		}
		
		return loadingCell;
	}
	
	NSArray* routes = [[self.sections objectAtIndex:indexPath.section] objectForKey:@"routes"];
	NSArray* phoneNumbers = [[self.sections objectAtIndex:indexPath.section] objectForKey:@"phoneNumbers"];


	NSString* cellID = @"Cell";
	UITableViewCell *cell = nil;
	
	
	if (nil != routes) 
	{
		cellID = @"RouteCell";
		cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		}
		
		ShuttleRoute* route = [routes objectAtIndex:indexPath.row];
		
		cell.textLabel.text = route.title;
			
		//ShuttleRoute *aRoute = [[[self.model.routes objectAtIndex:indexPath.section] objectForKey:@"routes"] objectAtIndex:indexPath.row];
		//NSString *cellText = aRoute.title;
		
		// Set up the cell...
		//cell.textLabel.text = cellText;
		cell.imageView.image = route.isRunning ? _shuttleRunningImage : _shuttleNotRunningImage;
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if(nil != phoneNumbers)
	{
		NSDictionary* phoneNumberInfo = [phoneNumbers objectAtIndex:indexPath.row];
		
		
		cellID = @"PhoneCell";
		cell = (SecondaryGroupedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[[SecondaryGroupedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		}
		
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		SecondaryGroupedTableViewCell* formattedCell = (SecondaryGroupedTableViewCell*)cell;
		formattedCell.textLabel.text = [phoneNumberInfo objectForKey:@"description"];
		formattedCell.secondaryTextLabel.text = [phoneNumberInfo objectForKey:@"formattedPhoneNumber"];
		formattedCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		
	}
	else
	{
		cellID = @"Cell";
		cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID] autorelease];
		}

		
		// check for text to display
		NSString* text = [[self.sections objectAtIndex:indexPath.section] objectForKey:@"text"];
		cell.textLabel.text = text;
	}

	
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSArray* routes = [[self.sections objectAtIndex:indexPath.section] objectForKey:@"routes"];
	NSArray* phoneNumbers = [[self.sections objectAtIndex:indexPath.section] objectForKey:@"phoneNumbers"];
	if (nil != routes) 
	{
		ShuttleRoute* route = [routes objectAtIndex:indexPath.row];

		
		ShuttleRouteViewController *routeVC = [[[ShuttleRouteViewController alloc] initWithNibName:@"ShuttleRouteViewController" bundle:nil ] autorelease];
		routeVC.route = route;
		
		
		/*
		RouteMapViewController* routeVC = [[[RouteMapViewController alloc] initWithNibName:@"RouteMapViewController" bundle:nil] autorelease];
		routeVC.route = route;
		*/
		
		[self.navigationController pushViewController:routeVC animated:YES];
		
	}
	
	else if(nil != phoneNumbers)
	{
		NSString* phoneNumber = [[phoneNumbers objectAtIndex:indexPath.row] objectForKey:@"phoneNumber"];

		NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(void) setShuttleRoutes:(NSArray *) shuttleRoutes
{
	[_shuttleRoutes release];
	_shuttleRoutes = [shuttleRoutes retain];
	
	
	// create saferide and non saferide arrays based on the data. 
	NSMutableArray* saferideRoutes = [NSMutableArray arrayWithCapacity:self.shuttleRoutes.count];
	NSMutableArray* nonSaferideRoutes = [NSMutableArray arrayWithCapacity:self.shuttleRoutes.count];
	
	for (ShuttleRoute* route in self.shuttleRoutes) {
		if (route.isSafeRide) {
			[saferideRoutes addObject:route];
		}
		else {
			[nonSaferideRoutes addObject: route];
		}
		
	}
	
	self.saferideRoutes = saferideRoutes;
	self.nonSaferideRoutes = nonSaferideRoutes;
	
	NSMutableArray* sections = [NSMutableArray array];
	
	if (self.shuttleRoutes.count > 0) {

		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Daytime Shuttles:", @"title", 
							 self.nonSaferideRoutes, @"routes", nil, nil]];
		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Nighttime Saferide Shuttles:", @"title", 
							  self.saferideRoutes, @"routes", nil, nil]];
		
	}
	else {
		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"No Shuttles Found",  @"text" , nil, nil]];
		
	}

	[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Contact Information", @"title", _contactInfo, @"phoneNumbers", nil, nil]];
		 
	self.sections = sections;
	
	
	[self.tableView reloadData];
}

- (void)refreshRoutes {
	[[ShuttleDataManager sharedDataManager] requestRoutes];
}


#pragma mark ShuttleDataManagerDelegate

// message sent when routes were received. If request failed, this is called with a nil routes array
-(void) routesReceived:(NSArray*) routes
{	
	self.isLoading = NO;
	NSArray *oldRoutes = self.shuttleRoutes;
	self.shuttleRoutes = routes;
	
	if (nil == routes) {
		UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Error Connecting"
														message:@"There was a problem retrieving shuttle data. Please check your connection and try again"
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil] autorelease];
		[alert show];
		
		self.shuttleRoutes = oldRoutes;
	}
}


@end

