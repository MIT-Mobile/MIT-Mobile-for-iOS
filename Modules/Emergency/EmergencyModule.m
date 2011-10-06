#import "EmergencyModule.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"

#import "MITModule+Protected.h"

@implementation EmergencyModule

@synthesize mainViewController = _mainViewController,
            didReadMessage = _didReadMessage;

- (id) init {
    self = [super init];
    if (self != nil) {
        // Basic settings
        self.tag = EmergencyTag;
        self.shortName = @"Emergency";
        self.longName = @"Emergency Info";
        self.iconName = @"emergency";
        self.pushNotificationSupported = YES;
        
        // preserve unread state
        if ([[NSUserDefaults standardUserDefaults] integerForKey:EmergencyUnreadCountKey] > 0) {
            // TODO: EmergencyUnreadCountKey doesn't seem to be used anywhere else
            // so we wouldn't ever get here
            self.badgeValue = @"1";
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewEmergencyInfo:) name:EmergencyInfoDidChangeNotification object:nil];
        
		_emergencyMessageLoaded = NO;
        self.didReadMessage = NO; // will be reset if any emergency data (old or new) is received
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoDidLoad:) name:EmergencyInfoDidLoadNotification object:nil];
		
        // check for new emergency info on app launch
        [[EmergencyData sharedData] checkForEmergencies];
    }
    return self;
}

- (void)applicationWillEnterForeground {
    _emergencyMessageLoaded = NO;
    [[EmergencyData sharedData] checkForEmergencies];
}

- (void)loadModuleHomeController
{
    EmergencyViewController *controller = [[[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    controller.delegate = self;
    
    self.mainViewController = controller;
    self.moduleHomeController = controller;
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
        
        didHandle = YES;
    }
    return didHandle;
}

- (BOOL)handleNotification:(MITNotification *)notification
                shouldOpen:(BOOL)shouldOpen {
	if(shouldOpen) {
		[self.mainViewController refreshInfo:nil];
		self.currentPath = @"";
        [[MITAppDelegate() rootNavigationController] popToRootViewControllerAnimated:NO];
        [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
	}
    
	return YES;
}

- (void)infoDidLoad: (id)object {
	_emergencyMessageLoaded = YES;
	[self syncUnreadNotifications];
}

- (void) syncUnreadNotifications {
	// if emergency module on the screen
	// and the emergency module has received data from the server (does not have to be new data)
	// since the last time it was on screen, we tell the server to clear the emergency badge
	
	if(_emergencyMessageLoaded && [[EmergencyData sharedData] didReadMessage]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
}

@end
