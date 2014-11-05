#import "EmergencyModule.h"

#import "MITUnreadNotifications.h"
#import "EmergencyData.h"
#import "EmergencyViewController.h"
#import "EmergencyContactsViewController.h"

@interface EmergencyModule ()
@property BOOL emergencyMessageLoaded;
@property(nonatomic,strong) id infoDidLoadToken;
@end

@implementation EmergencyModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagEmergency title:@"Emergency"];
    if (self) {
        self.longTitle = @"Emergency Info";
        self.imageName = MITImageEmergencyModuleIcon;
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.infoDidLoadToken];
}

- (void)viewControllerDidLoad
{
    [super viewControllerDidLoad];
    
    // TODO: Find a better spot for this
    if (!self.infoDidLoadToken) {
        __weak EmergencyModule *weakSelf = self;
        self.infoDidLoadToken = [[NSNotificationCenter defaultCenter] addObserverForName:EmergencyInfoDidLoadNotification
                                                                                  object:nil
                                                                                   queue:nil
                                                                              usingBlock:^(NSNotification *note) {
                                                                                  EmergencyModule *blockSelf = weakSelf;

                                                                                  if (blockSelf) {
                                                                                      blockSelf.emergencyMessageLoaded = YES;
                                                                                      [blockSelf syncUnreadNotifications];
                                                                                  }
                                                                              }];
        // check for new emergency info on app launch
        [[EmergencyData sharedData] checkForEmergencies];
    }
}

- (void)loadRootViewController
{
    EmergencyViewController *rootViewController = [[EmergencyViewController alloc] initWithStyle:UITableViewStyleGrouped];
    rootViewController.delegate = self;
    self.rootViewController = rootViewController;
}

- (void)didReceiveRequestWithURL:(NSURL*)url
{
    [super didReceiveRequestWithURL:url];
    
    NSArray *pathComponents = url.pathComponents;
    
    if ([[pathComponents firstObject] isEqualToString:@"contacts"]) {
        // TODO: Stuff like this would probably be much more suited for a method
        // like willShowModuleWithURL:animated: (or something like that)
        
        UIViewController *topViewController = self.navigationController.topViewController;
        
        if (![topViewController isKindOfClass:[EmergencyContactsViewController class]]) {
            [self.navigationController popToRootViewControllerAnimated:NO];
            EmergencyContactsViewController *contactsViewController = [[EmergencyContactsViewController alloc] init];
            [self.navigationController pushViewController:contactsViewController animated:NO];
        }
    }
}

- (void)didReceiveNotification:(NSDictionary *)userInfo
{
    [super didReceiveNotification:userInfo];
    [self.rootViewController refreshInfo:nil];
}

- (void) syncUnreadNotifications {
	// if emergency module on the screen
	// and the emergency module has received data from the server (does not have to be new data)
	// since the last time it was on screen, we tell the server to clear the emergency badge
	
	if(self.emergencyMessageLoaded && [[EmergencyData sharedData] didReadMessage]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.name];
	}
}

@end
