#import "EmergencyModule.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"

@implementation EmergencyModule

@synthesize mainViewController, didReadMessage;

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
        //self.mainViewController = [[[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        //self.mainViewController.delegate = self; // to receive -didReadNewestEmergencyInfo
        
        //[self.tabNavController setViewControllers:[NSArray arrayWithObject:mainViewController]];
        
        // preserve unread state
        if ([[NSUserDefaults standardUserDefaults] integerForKey:EmergencyUnreadCountKey] > 0) {
            // TODO: EmergencyUnreadCountKey doesn't seem to be used anywhere else
            // so we wouldn't ever get here
            self.badgeValue = @"1";
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewEmergencyInfo:) name:EmergencyInfoDidChangeNotification object:nil];
        
		emergencyMessageLoaded = NO;
        didReadMessage = NO; // will be reset if any emergency data (old or new) is received
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidLoad:) name:EmergencyInfoDidLoadNotification object:nil];
		
        // check for new emergency info on app launch
        [[EmergencyData sharedData] checkForEmergencies];
    }
    return self;
}

- (void)applicationWillEnterForeground {
    emergencyMessageLoaded = NO;
    [[EmergencyData sharedData] checkForEmergencies];
}

- (UIViewController *)moduleHomeController {
    if (!self.mainViewController) {
        self.mainViewController = [[[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        self.mainViewController.delegate = self; // to receive -didReadNewestEmergencyInfo
    }
    return self.mainViewController;
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    BOOL didHandle = NO;
    if ([localPath isEqualToString:@"contacts"]) {
        UINavigationController *controller = [MITAppDelegate() rootNavigationController];
        
        if (![controller.visibleViewController isKindOfClass:[EmergencyContactsViewController class]]) {
            
            // show More Emergency Contact drilldown
            // init its view controller
            EmergencyContactsViewController *contactsVC = [[[EmergencyContactsViewController alloc] initWithNibName:nil bundle:nil] autorelease];
            // push it onto the navigation stack
            [controller pushViewController:contactsVC
                                  animated:YES];
        }
        [self becomeActiveTab];
        didHandle = YES;
    }
    return didHandle;
}

- (BOOL)handleNotification:(MITNotification *)notification shouldOpen: (BOOL)shouldOpen {
	if(shouldOpen) {
		[self popToRootViewController];
		[mainViewController refreshInfo:nil];
		self.currentPath = @"";
		[self becomeActiveTab];
	}
	return YES;
}

- (void)infoDidLoad: (id)object {
	emergencyMessageLoaded = YES;
	[self syncUnreadNotifications];
}

- (void) syncUnreadNotifications {
	// if emergency module on the screen
	// and the emergency module has received data from the server (does not have to be new data)
	// since the last time it was on screen, we tell the server to clear the emergency badge
	
	if(emergencyMessageLoaded && [[EmergencyData sharedData] didReadMessage]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
}

@end
