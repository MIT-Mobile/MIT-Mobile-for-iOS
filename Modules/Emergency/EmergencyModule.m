#import "EmergencyModule.h"

#import "EmergencyData.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"
#import "MITModule+Protected.h"

@interface EmergencyModule ()
@property BOOL emergencyMessageLoaded;
@property (strong) id infoDidLoadToken;
@end

@implementation EmergencyModule
- (id) init {
    self = [super init];
    if (self) {
        // Basic settings
        self.tag = EmergencyTag;
        self.shortName = @"Emergency";
        self.longName = @"Emergency Info";
        self.iconName = @"emergency";
        self.pushNotificationSupported = YES;
        
        _infoDidLoadToken = [[NSNotificationCenter defaultCenter] addObserverForName:EmergencyInfoDidLoadNotification
                                                                              object:nil
                                                                               queue:nil
                                                                          usingBlock:^(NSNotification *note) {
                                                                              self.emergencyMessageLoaded = YES;
                                                                              [self syncUnreadNotifications];
                                                                          }];
        // check for new emergency info on app launch
        [[EmergencyData sharedData] checkForEmergencies];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.infoDidLoadToken];
}

- (void)applicationWillEnterForeground {
    self.emergencyMessageLoaded = NO;
    [[EmergencyData sharedData] checkForEmergencies];
}

- (void)loadModuleHomeController
{
    EmergencyViewController *controller = [[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
            EmergencyContactsViewController *contactsVC = [[EmergencyContactsViewController alloc] initWithNibName:nil bundle:nil];
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

- (void) syncUnreadNotifications {
	// if emergency module on the screen
	// and the emergency module has received data from the server (does not have to be new data)
	// since the last time it was on screen, we tell the server to clear the emergency badge
	
	if(self.emergencyMessageLoaded && [[EmergencyData sharedData] didReadMessage]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
}

@end
