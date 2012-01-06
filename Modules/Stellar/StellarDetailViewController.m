#import "MIT_MobileAppDelegate.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"
#import "MITUnreadNotifications.h"
#import "StellarDetailViewController.h"
#import "UIKit+MITAdditions.h"
#import "NewsDataSource.h"
#import "InfoDataSource.h"
#import "StaffDataSource.h"
#import "MITUIConstants.h"

#define leftMargin 10.0
#define verticalPadding 10.0
#define lineHeight 25.0
#define headerHeight 150.0
#define footerHeight 20.0
#define tabHeight 36.0
#define termHeight 20.0
#define paddingHeight 5.0
#define buttonWidth  78
#define buttonHeight 38
#define myStellarPadding 10.0

NSString * termText(NSString *termCode) {
	NSString *season = [termCode substringWithRange:NSMakeRange(0, 2)];
	NSString *year = [termCode substringFromIndex:2];
	
	NSString *seasonName = nil;
	if([season isEqualToString:@"sp"]) {
		seasonName = @"Spring";
	} else if([season isEqualToString:@"fa"]) {
		seasonName = @"Fall";
	} else if([season isEqualToString:@"ia"]) {
		seasonName = @"IAP";
	} else if([season isEqualToString:@"su"]) {
		seasonName = @"Summer";
	}
	
	return [NSString stringWithFormat:@"%@ 20%@", seasonName, year];
}

@interface StellarDetailViewController (Private)
- (void) resizeFooter;
- (void) switchTab:(NSInteger)index;
- (void) setCurrentTabName: (NSString *)tabName;
@end

@implementation StellarDetailViewController
@synthesize stellarClass;
@synthesize currentClassInfoLoader, myStellarStatusDelegate;
@synthesize news, instructors, tas, times;
@synthesize titleView, termView;
@synthesize myStellarButton;
@synthesize dataSources;
@synthesize loadingState;
@synthesize url;
@synthesize refreshClass;

+ (StellarDetailViewController *) launchClass: (StellarClass *)stellarClass viewController: (UIViewController *)controller {
	StellarDetailViewController *detailViewController = [[StellarDetailViewController alloc] initWithClass:stellarClass];
	[controller.navigationController pushViewController:detailViewController animated:YES];
	return [detailViewController autorelease];
}

- (id) initWithClass: (StellarClass *)class {
	self = [super initWithStyle:UITableViewStylePlain];
	if (self) {
		self.stellarClass = class;
		
		self.news = [NSArray array];
		self.instructors = [NSArray array];
		self.tas = [NSArray array];
		self.times = [NSArray array];
		
		self.dataSources = [[[NSMutableArray alloc] initWithCapacity:3] autorelease];
		
		actionButton = nil;
		
		[self setCurrentTabName: @"News"];
		currentTabNames = [[NSMutableArray alloc] initWithCapacity:3];
		tabViewControl = nil;
		myStellarButton = nil;
		loadingState = StellarNewsLoadingInProcess;
		url = [[MITModuleURL alloc] initWithTag:StellarTag];
		self.title = @"Class Info";
		refreshClass = YES;
	}
	return self;
}

- (void) dealloc {
	[url release];
	
	currentClassInfoLoader.viewController = nil;
	myStellarStatusDelegate.viewController = nil;
	
	[currentClassInfoLoader release];
	[myStellarStatusDelegate release];
	
	[stellarClass release];
	
	[actionButton release];
	
	[news release];
	[instructors release];
	[tas release];
	[times release];
	
	[currentTabNames release];
	[self setCurrentTabName:nil];
	[dataSources release];
	
	[super dealloc];
}

- (void) viewDidLoad {
	
	self.tableView.tableHeaderView = [[[UIView alloc]
		initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, headerHeight)] autorelease];
	
	self.tableView.tableFooterView = [[[UIView alloc]
		initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, footerHeight)] autorelease];
	self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
	
	[self.tableView applyStandardColors];
	
	CGRect titleFrame = CGRectMake(
		leftMargin, verticalPadding,
		self.tableView.tableHeaderView.frame.size.width-2*leftMargin-buttonWidth-myStellarPadding-2, headerHeight);
	self.titleView = [[[UILabel alloc] initWithFrame:titleFrame] autorelease];
	self.titleView.lineBreakMode = UILineBreakModeWordWrap;
	self.titleView.numberOfLines = 0;
	self.titleView.font = [UIFont fontWithName:BOLD_FONT size:20.0];
	self.titleView.backgroundColor = [UIColor clearColor];
	[self.tableView.tableHeaderView addSubview:self.titleView];
	
	self.termView = [[[UILabel alloc] initWithFrame:CGRectMake(leftMargin, 0, 100.0, termHeight)] autorelease];
	self.termView.font = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
	self.termView.backgroundColor = [UIColor clearColor];
	[self.tableView.tableHeaderView addSubview:self.termView];
	
	// initialize the myStellar button
	myStellarButton = [UIButton buttonWithType:UIButtonTypeCustom];
	myStellarButton.frame = CGRectMake(
		self.tableView.tableHeaderView.frame.size.width-leftMargin-buttonWidth, myStellarPadding,
		buttonWidth, buttonHeight);
	myStellarButton.enabled = NO;
	[myStellarButton setImage:[UIImage imageNamed:@"stellar/mystellar-off.png"] forState:UIControlStateNormal];
	[myStellarButton setImage:[UIImage imageNamed:@"stellar/mystellar-off-pressed.png"] forState:(UIControlStateNormal | UIControlStateHighlighted)];
	[myStellarButton setImage:[UIImage imageNamed:@"stellar/mystellar-on.png"] forState:UIControlStateSelected];
	[myStellarButton setImage:[UIImage imageNamed:@"stellar/mystellar-on-pressed.png"] forState:(UIControlStateSelected | UIControlStateHighlighted)];
	[myStellarButton addTarget:self action:@selector(myStellarButtonToggled) forControlEvents:UIControlEventTouchUpInside];
	[self.tableView.tableHeaderView addSubview:myStellarButton];
	
	// initialize the action button
	actionButton = [[UIBarButtonItem alloc] initWithTitle:@"Stellar Site" style:UIBarButtonItemStylePlain target:self action:@selector(openSite)];
	actionButton.enabled = NO; // will enabled it when valid actions are known to exist
	self.navigationItem.rightBarButtonItem = actionButton;
	
	if (refreshClass) {
		// initiate server-side data collection
		self.currentClassInfoLoader = [[ClassInfoLoader new] autorelease];
		self.currentClassInfoLoader.viewController = self;
	
		[StellarModel loadAllClassInfo:self.stellarClass delegate:self.currentClassInfoLoader];
	} else {
		// this mode is used in instances when we want to disable refresh
		// specifically if loading up a news item from the previous use of the app
		loadingState = StellarNewsLoadingFailed;
		[self loadClassInfo:self.stellarClass];
		// we normally wait till the class info is loaded to enable this button
		// because we not loading from server, we just enable it now
		myStellarButton.enabled = YES;
	}
	
	[url setPath:[NSString stringWithFormat:@"class/%@/News", self.stellarClass.masterSubjectId] query:nil];
}

- (void) viewDidAppear:(BOOL)animated {
	[url setAsModulePath];
}

- (void) myStellarButtonToggled {
	BOOL newMyStellarStatus = !myStellarButton.selected;
	NSString *action = newMyStellarStatus ? @"subscribe" : @"unsubscribe";
	
	MITIdentity *identity = [MITDeviceRegistration identity];
	if(identity) {
		NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
		[parameters setObject:action forKey:@"action"];
		[parameters setObject:stellarClass.masterSubjectId forKey:@"subject"];
		[parameters setObject:stellarClass.term forKey:@"term"];
	
		self.myStellarStatusDelegate = [[[MyStellarStatusDelegate alloc] initWithClass:stellarClass status:newMyStellarStatus viewController:self] autorelease];
		[[MITMobileWebAPI jsonLoadedDelegate:myStellarStatusDelegate]
			requestObjectFromModule:StellarTag command:@"myStellar" parameters:parameters];

		myStellarButton.selected = !(myStellarButton.selected);
	} else {
		NSString *message;
		if([[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone) {
			message = @"Notifications are currently disabled, Quit this application and go to Settings > Notifications to enable them.";
		} else {
			message = @"Can not register your device for myStellar notifications, try restarting the application to register device.";
		}

		UIAlertView *alert = [[UIAlertView alloc] 
			initWithTitle:@"Unregistered Device"
			message:message
			delegate:nil
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

// this method is only activated by an actual user interaction with the tab
- (void) tabControl: (TabViewControl*)control changedToIndex:(int)tabIndex tabText:(NSString*)tabText {
	[self setCurrentTabName:tabText];
	[self switchTab:tabIndex];
	
	// save the tab state
	[url setPath:[NSString stringWithFormat:@"class/%@/%@", self.stellarClass.masterSubjectId, currentTabName] query:nil];
	[url setAsModulePath];
}

- (void) resizeFooter {
	// we resize the footer so that it fills up the rest of the screen but not much more
	CGFloat tableHeight = [((id<StellarDetailTableViewDelegate>)self.tableView.delegate) heightOfTableView:self.tableView] + self.tableView.tableHeaderView.frame.size.height;
	CGFloat footerFrameHeight = footerHeight + self.view.frame.size.height - tableHeight;
	if(footerFrameHeight < footerHeight) {
		footerFrameHeight = footerHeight;
	}
	
	CGRect footerFrame = self.tableView.tableFooterView.frame;
	footerFrame.size.height = footerFrameHeight;
	self.tableView.tableFooterView.frame = footerFrame;
}

- (void) addTabName: (NSString *)name dataSource: (id)dataSource {
	[currentTabNames addObject:name];
	[dataSources addObject:dataSource];
	[tabViewControl addTab:name];
}
	
- (void) buildTabs: (CGFloat)originY {
	[tabViewControl removeFromSuperview];
	tabViewControl = nil;
	
	//remove all the objects for any old tabs
	[currentTabNames removeAllObjects];
	[dataSources removeAllObjects];
	
	tabViewControl = [[TabViewControl alloc]
		initWithFrame:CGRectMake(0, originY, self.tableView.tableHeaderView.frame.size.width, tabHeight)];
	tabViewControl.delegate = self;
	
	// determine which tabs need to be displayed
	[self addTabName:@"News" dataSource:[NewsDataSource viewController:self]];

	if([stellarClass.blurb length]) {
		[self addTabName:@"Info" dataSource:[InfoDataSource viewController:self]];
	}
	if([instructors count]+[tas count]) {
		[self addTabName:@"Staff" dataSource:[StaffDataSource viewController:self]];
	}
	
	[self setCurrentTab:currentTabName];	
	[self.tableView.tableHeaderView addSubview:tabViewControl];
	[tabViewControl release];
}	


// this method is always called when tabs change (no matter what initiates the change)
- (void) switchTab: (NSInteger)index {
	// set the dataSource and delegate based on current tab
	// and tell the tabViewControl the tab we want open
	self.tableView.delegate = [dataSources objectAtIndex:index];
	self.tableView.dataSource = [dataSources objectAtIndex:index];
	tabViewControl.selectedTab = index;
	
	[self resizeFooter];
	[self.tableView reloadData];
}

- (void) setCurrentTab: (NSString *)tabName {
	[self setCurrentTabName:tabName];
	if (currentTabNames.count) {
		// manually search for the tab, could not find a builtin API to do this
		NSUInteger activeIndex = NSNotFound;
		for (NSUInteger index=0; index < currentTabNames.count; index++) {
			if ([[currentTabNames objectAtIndex:index] isEqualToString:tabName]) {
				activeIndex = index;
				break;
			}
		}

		if(activeIndex == NSNotFound) {
            [self setCurrentTabName:[currentTabNames objectAtIndex:0]];
			activeIndex = 0;
		}

		[self switchTab:activeIndex];
	}
}
	
- (void) loadClassInfo: (StellarClass *)class {
	self.stellarClass = class;
	
	myStellarButton.selected = [class.isFavorited boolValue];

	// order the news and staff for display
	self.news = [StellarModel sortedAnnouncements:class];
	self.instructors = [[[class.staff allObjects]
		filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type like 'instructor'"]]
		sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
	
	self.tas = [[[class.staff allObjects]
		filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type like 'ta'"]]
		sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
	
	self.times = [class.times allObjects];
	self.times = [self.times 
		sortedArrayUsingDescriptors:[NSArray 
		arrayWithObject:[ [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES] autorelease]]];
					
	NSString *classTitle = [[class.name stringByAppendingString:@": "] stringByAppendingString:class.title];
	CGFloat classTitleHeight = [classTitle
		sizeWithFont:self.titleView.font
		constrainedToSize:CGSizeMake(self.titleView.frame.size.width, headerHeight)         
		lineBreakMode:UILineBreakModeWordWrap].height;

	// reposition the contents of all the header items based on the size of the title
	// several frames will need to be readjusted
	CGRect newFrame = self.termView.frame;
	newFrame.origin.y = classTitleHeight + verticalPadding;
	self.termView.frame = newFrame;
	
	newFrame = self.titleView.frame;
	newFrame.size.height = classTitleHeight;
	self.titleView.frame = newFrame;	
	
	self.titleView.text = classTitle;
	self.termView.text = termText(class.term);
	
	CGFloat classAndTermHeight = classTitleHeight + termHeight + verticalPadding + paddingHeight;
	[self buildTabs:classAndTermHeight];	
	
	newFrame = self.tableView.tableHeaderView.frame;
	newFrame.size.height = classAndTermHeight + tabHeight;
	self.tableView.tableHeaderView.frame = newFrame;
	self.tableView.tableHeaderView = self.tableView.tableHeaderView; //strangely enough this seems to be required
	
	// check if any "Actions" are available
	// Actions = (loading the stellar site) or (toggling favorites which requires data loading to be complete)
	if([class.url length]) {
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

- (void) openSite {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"http://stellar.mit.edu" stringByAppendingString:stellarClass.url]]];
}	

- (BOOL) dataLoadingComplete {
	return (loadingState != StellarNewsLoadingInProcess);
}

- (void) setCurrentTabName: (NSString *)tabName {
	if (currentTabName != tabName) {
		[currentTabName release];
		currentTabName = [tabName retain];
	}
}


@end

@implementation ClassInfoLoader
@synthesize viewController;

- (void) generalClassInfoLoaded: (StellarClass *)class {
	if(self.viewController.currentClassInfoLoader == self) {
		[self.viewController loadClassInfo:class];
	}
}

- (void) initialAllClassInfoLoaded: (StellarClass *)class {
	if(self.viewController.currentClassInfoLoader == self) {
		if(class) {
			[self.viewController loadClassInfo:class];
		} else {
			self.viewController.myStellarButton.selected = NO;
		}
		
		// enough data is now available to configure the state of myStellar button
		self.viewController.myStellarButton.enabled = YES;
	}
}

- (void) finalAllClassInfoLoaded: (StellarClass *)class {
	if(self.viewController.currentClassInfoLoader == self) {
		self.viewController.loadingState = StellarNewsLoadingSucceeded;
		[self.viewController loadClassInfo:class];
		
		MITNotification *notification = [[MITNotification alloc] initWithModuleName:StellarTag noticeId:class.masterSubjectId];
		if([MITUnreadNotifications hasUnreadNotification:notification]) {
			[MITUnreadNotifications removeNotifications:[NSArray arrayWithObject:notification]];
		}
		[notification release];
		self.viewController.myStellarButton.enabled = YES;
	}
}

- (void) showErrorWithTitle: (NSString *)errorTitle message: (NSString *)message {
	if(self.viewController.currentClassInfoLoader == self) {
		self.viewController.loadingState = StellarNewsLoadingFailed;
		[self.viewController.tableView reloadData];
		if(errorTitle) {
			UIAlertView *alert = [[UIAlertView alloc] 
				initWithTitle:errorTitle 
				message:message
				delegate:nil
				cancelButtonTitle:@"OK" 
				otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
}
	
- (void) handleClassNotFound {
	[self showErrorWithTitle:@"Class not found" message:@"This is probably an old class or a class not being taught this semester"];
}

- (void) handleCouldNotReachStellar {
	[self showErrorWithTitle:nil message:nil];
}
	
@end

@implementation StellarDetailViewControllerComponent
@synthesize viewController;

+ (StellarDetailViewControllerComponent *) viewController: (StellarDetailViewController *)controller {
	StellarDetailViewControllerComponent *component = [self new];
	component.viewController = controller;
	return [component autorelease];
}

@end

@implementation MyStellarStatusDelegate
@synthesize viewController;
- (id) initWithClass: (StellarClass *)class status: (BOOL)newStatus viewController: (StellarDetailViewController *)controller {
	self = [super init];
	if (self) {
		viewController = controller;
		status = newStatus;
		stellarClass = [class retain];
	}
	return self;
}

- (void) dealloc {
	[stellarClass release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)JSONObject {
	if(status) {
		[StellarModel saveClassToFavorites:stellarClass];
	} else {
		[StellarModel removeClassFromFavorites:stellarClass];
	}
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	if(viewController.myStellarStatusDelegate == self) {
		viewController.myStellarButton.selected = [stellarClass.isFavorited boolValue];
	}
	
	UIAlertView *alert = [[UIAlertView alloc] 
		initWithTitle:@"Connection failed"
		message:[NSString stringWithFormat:@"Could not update your myStellar account for %@", stellarClass.masterSubjectId]
		delegate:nil
		cancelButtonTitle:@"OK" 
		otherButtonTitles:nil];
	
	[alert show];
    [alert release];
}		

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return NO;
}

@end

void makeCellWhite(UITableViewCell *cell) {
	cell.backgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
	cell.backgroundView.backgroundColor = [UIColor whiteColor];
}
