#import "ShuttleRoutes.h"

#import "ShuttleRoute.h"
#import "ShuttleRouteViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

@interface ShuttleRoutes ()
{
	
	UIImage* _shuttleRunningImage;
	UIImage* _shuttleNotRunningImage;
	UIImage *_shuttleLoadingImage;
    
	NSArray* _contactInfo;
    
	NSArray* _extraLinks;
}

@end

@implementation ShuttleRoutes

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Shuttles";
    }
    return self;
}


- (void)viewDidUnload {
	
	[[ShuttleDataManager sharedDataManager] unregisterDelegate:self];
	

}


- (void)viewDidLoad {
    [super viewDidLoad];
    
	// TODO: these phone numbers and links should be provided by the server, not hardcoded
	_contactInfo = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Parking Office", @"description",
																						 @"16172586510", @"phoneNumber", 
																						 @"617.258.6510", @"formattedPhoneNumber", nil, nil],
					 [NSDictionary dictionaryWithObjectsAndKeys:@"Saferide", @"description",
																@"16172532997", @"phoneNumber",
					  @"617.253.2997", @"formattedPhoneNumber", nil, nil], nil];
	
    _extraLinks = [NSArray arrayWithObjects:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     @"Real-time Bus Arrivals", @"description",
                     @"http://www.nextbus.com/webkit", @"url", nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     @"Real-time Train Arrivals", @"description",
                     @"http://www.mbtainfo.com/", @"url", nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     @"Google Transit", @"description",
                     @"http://www.google.com/transit", @"url", nil],
                    nil];
    
	_shuttleRunningImage = [UIImage imageNamed:@"shuttle/shuttle.png"];
	_shuttleNotRunningImage = [UIImage imageNamed:@"shuttle/shuttle-off.png"];
    
    UIGraphicsBeginImageContext(CGSizeMake(18, 19));
    _shuttleLoadingImage = UIGraphicsGetImageFromCurrentImageContext();
	
    self.tableView.backgroundView = nil;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    } else {
        self.tableView.backgroundColor = [UIColor mit_backgroundColor];
    }

	ShuttleDataManager* dataManager = [ShuttleDataManager sharedDataManager];
	[dataManager registerDelegate:self];
    
	[self setShuttleRoutes:[dataManager shuttleRoutes]];
	self.isLoading = YES;
	[dataManager requestRoutes];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshRoutes)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
    // if they're going to display, and we're not currently loading and we haven't retrieved any routes, try again
	if (!self.isLoading && self.shuttleRoutes == nil) {
		self.isLoading = YES;
		[[ShuttleDataManager sharedDataManager] requestRoutes];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[MIT_MobileAppDelegate moduleForTag:ShuttleTag] resetURL];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Table view delegation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (nil == _shuttleRoutes) {
		return 1;
	}
	
	return [self.sections count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	NSArray* routes = self.sections[section][@"routes"];
	if (nil != routes) {
		return [routes count];
	}
	
	NSArray* phoneNumbers = self.sections[section][@"phoneNumbers"];
	if (nil != phoneNumbers) {
		return [phoneNumbers count];
	}
    
	NSArray* urls = self.sections[section][@"urls"];
	if (nil != urls) {
		return [urls count];
	}
    
	// one row for "no data found"
	return 1;
	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSArray* routes = self.sections[indexPath.section][@"routes"];
	NSArray* phoneNumbers = self.sections[indexPath.section][@"phoneNumbers"];
	NSArray* urls = self.sections[indexPath.section][@"urls"];


	NSString* cellID = @"Cell";
	UITableViewCell *cell = nil;
	
	
	if (nil != routes) 
	{
		cellID = @"RouteCell";
		cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		}
		
		ShuttleRoute* route = routes[indexPath.row];
		
		cell.textLabel.text = route.title;
		
		if (_isLoading) {
			cell.imageView.image = _shuttleLoadingImage;
			UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			// TODO: hard coded values for center
			spinny.center = CGPointMake(18.0, 22.0);
			[spinny startAnimating];
			[cell.contentView addSubview:spinny];
		} else {
			for (UIView *aView in cell.contentView.subviews) {
				if ([aView isKindOfClass:[UIActivityIndicatorView class]]) {
					[aView removeFromSuperview];
				}
			}
			cell.imageView.image = route.isRunning ? _shuttleRunningImage : _shuttleNotRunningImage;
		}

		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if(nil != phoneNumbers)
	{
		NSDictionary* phoneNumberInfo = phoneNumbers[indexPath.row];
		
		
		cellID = @"PhoneCell";
		cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
            cell.detailTextLabel.textColor = [UIColor darkGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
		}
		
		cell.textLabel.text = phoneNumberInfo[@"description"];
		cell.detailTextLabel.text = phoneNumberInfo[@"formattedPhoneNumber"];
	}
	else if(nil != urls)
	{
		NSDictionary* urlInfo = urls[indexPath.row];
		
		
		cellID = @"URLCell";
		cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		}
		
		cell.textLabel.text = urlInfo[@"description"];
		cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
		
	}
	else
	{
		cellID = @"Cell";
		cell = [tableView dequeueReusableCellWithIdentifier:cellID];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		}

        if (self.isLoading) {
            cell.textLabel.text = @"Loading...";
            
            cell.imageView.image = _shuttleLoadingImage;
			UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			// TODO: hard coded values for center
			spinny.center = CGPointMake(18.0, 22.0);
			[spinny startAnimating];
			[cell.contentView addSubview:spinny];
        } else {
            cell.textLabel.text = self.sections[indexPath.section][@"text"];
            
            for (UIView *aView in cell.contentView.subviews) {
				if ([aView isKindOfClass:[UIActivityIndicatorView class]]) {
					[aView removeFromSuperview];
				}
			}
        }
	}

	
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* phoneNumbers = self.sections[indexPath.section][@"phoneNumbers"];

    if (phoneNumbers != nil) {
        // There's probably a better way to do this —
        // one that doesn't require hardcoding expected padding.
        
        // UITableViewCellStyleSubtitle layout differs between iOS 6 and 7
        static UIEdgeInsets labelInsets;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            labelInsets = UIEdgeInsetsMake(11., 15., 11., 34. + 2.);
        } else {
            labelInsets = UIEdgeInsetsMake(11., 10. + 10., 11., 10. + 39.);
        }
        
        NSString *title = phoneNumbers[indexPath.row][@"description"];
        NSString *detail = phoneNumbers[indexPath.row][@"formattedPhoneNumber"];
        
        CGFloat availableWidth = CGRectGetWidth(UIEdgeInsetsInsetRect(tableView.bounds, labelInsets));
        CGSize titleSize = [title sizeWithFont:[UIFont systemFontOfSize:[UIFont buttonFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByWordWrapping];
        
        CGSize detailSize = [detail sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]] constrainedToSize:CGSizeMake(availableWidth, 2000) lineBreakMode:NSLineBreakByTruncatingTail];
        
        return MAX(titleSize.height + detailSize.height + labelInsets.top + labelInsets.bottom, tableView.rowHeight);
    } else {
        return self.tableView.rowHeight;
    }

}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSArray* routes = self.sections[indexPath.section][@"routes"];
	NSArray* phoneNumbers = self.sections[indexPath.section][@"phoneNumbers"];
	NSArray* urls = self.sections[indexPath.section][@"urls"];

	if (nil != routes) 
	{
		ShuttleRoute* route = routes[indexPath.row];

        ShuttleRouteViewController *routeVC;
        routeVC = [[ShuttleRouteViewController alloc] initWithNibName:@"ShuttleRouteViewController" bundle:nil];
		routeVC.route = route;
		
		[self.navigationController pushViewController:routeVC animated:YES];
		
	}
	
	else if(nil != phoneNumbers)
	{
		NSString* phoneNumber = phoneNumbers[indexPath.row][@"phoneNumber"];

		NSURL *externURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}

	else if(nil != urls)
	{
		NSString* url = urls[indexPath.row][@"url"];
        
		NSURL *externURL = [NSURL URLWithString:url];
		if ([[UIApplication sharedApplication] canOpenURL:externURL])
			[[UIApplication sharedApplication] openURL:externURL];
	}
}

- (void)setShuttleRoutes:(NSArray *) shuttleRoutes
{
	_shuttleRoutes = shuttleRoutes;
	
	
	// create saferide and non saferide arrays based on the data. 
	NSMutableArray* saferideRoutes = [NSMutableArray arrayWithCapacity:[self.shuttleRoutes count]];
	NSMutableArray* nonSaferideRoutes = [NSMutableArray arrayWithCapacity:[self.shuttleRoutes count]];
	
	for (ShuttleRoute* route in self.shuttleRoutes) {
		if (route.isSafeRide) {
			[saferideRoutes addObject:route];
		} else {
			[nonSaferideRoutes addObject: route];
		}
		
	}
	
	self.saferideRoutes = saferideRoutes;
	self.nonSaferideRoutes = nonSaferideRoutes;
	
	NSMutableArray* sections = [NSMutableArray array];
	
	if ([self.shuttleRoutes count] > 0) {

		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Daytime Shuttles", @"title",
							 self.nonSaferideRoutes, @"routes", nil, nil]];
		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Nighttime Saferide Shuttles", @"title",
							  self.saferideRoutes, @"routes", nil, nil]];
		
	}
	else {
		[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"No Shuttles Found",  @"text" , nil, nil]];
		
	}

	[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Contact Information", @"title", _contactInfo, @"phoneNumbers", nil, nil]];

    [sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"MBTA Information", @"title", _extraLinks, @"urls", nil, nil]];

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
        [UIAlertView alertViewForError:nil withTitle:@"Shuttles" alertViewDelegate:nil];
		self.shuttleRoutes = oldRoutes;
	}
}


@end

