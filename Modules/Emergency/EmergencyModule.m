#import "EmergencyModule.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"

@implementation EmergencyModule

@synthesize mainViewController;

- (id) init {
    self = [super init];
    if (self != nil) {
        // Basic settings
        self.tag = EmergencyTag;
        self.shortName = @"Emergency";
        self.longName = @"Emergency Info";
        self.iconName = @"emergency";
        self.pushNotificationSupported = YES;
        
        // Initial view at app launch
        self.mainViewController = [[[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        self.mainViewController.delegate = self; // to receive -didReadNewestEmergencyInfo
        
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:mainViewController]];
        
        // preserve unread state
        if ([[NSUserDefaults standardUserDefaults] integerForKey:EmergencyUnreadCountKey] > 0) {
            self.badgeValue = @"1";
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewEmergencyInfo:) name:EmergencyInfoDidChangeNotification object:nil];
        
		emergencyMessageLoaded = NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidLoad:) name:EmergencyInfoDidLoadNotification object:nil];
		
        // check for new emergency info on app launch
        [[EmergencyData sharedData] checkForEmergencies];
    }
    return self;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
    if ([localPath isEqualToString:@"contacts"]) {
        // show emergency contacts
        if (![mainViewController.navigationController.visibleViewController isKindOfClass:[EmergencyContactsViewController class]]) {
            
            // show More Emergency Contact drilldown
            // init its view controller
            EmergencyContactsViewController *contactsVC = [[EmergencyContactsViewController alloc] initWithNibName:nil bundle:nil];
            // push it onto the navigation stack
            [mainViewController.navigationController pushViewController:contactsVC animated:NO];
            [contactsVC release];
        }
        [self becomeActiveTab];
        didHandle = YES;
    }
    return didHandle;
}

- (void)didReceiveNewEmergencyInfo:(NSNotification *)aNotification {    
    // uncomment to show a popup dialog of the current emergency
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MIT Emergency Update" message:info delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
//    [alertView release];
}

- (BOOL)handleNotification:(MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen {
	if(shouldOpen) {
		[self popToRootViewController];
		[mainViewController refreshInfo:nil];
		self.currentPath = @"";
		hasLaunchedBegun = YES;
		[self becomeActiveTab];
	}
	return YES;
}

- (void)infoDidLoad: (id)object {
	emergencyMessageLoaded = YES;
	[self syncUnreadNotifications];
}

- (void) didAppear {
	[self syncUnreadNotifications];
}

- (void) syncUnreadNotifications {
	// if emergency module on the screen
	// and the emergency module has received data from the server (does not have to be new data)
	// since the last time it was on screen, we tell the server to clear the emergency badge
	
	if(emergencyMessageLoaded && self.mainViewController.view.superview && [self isActiveTab]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
		emergencyMessageLoaded = NO;
	}
}

@end
