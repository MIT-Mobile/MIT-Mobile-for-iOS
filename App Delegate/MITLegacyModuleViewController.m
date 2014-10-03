#import "MITLegacyModuleViewController.h"
#import "MITModule.h"

@implementation MITLegacyModuleViewController
@synthesize module = _module;

- (id)initWithModule:(MITModule*)module
{
    NSParameterAssert(module);
    
    self = [super init];
    
    if (self) {
        _module = module;
        
        MITModuleItem *item = [[MITModuleItem alloc] initWithTag:module.tag
                                                           title:module.shortName
                                                           image:module.springboardIcon];
        self.moduleItem = item;
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (MITModuleItem*)moduleItem
{
    MITModuleItem *moduleItem = self.moduleItem;
    moduleItem.badgeValue = self.module.badgeValue;
    return moduleItem;
}

- (void)loadRootViewController
{
    UIViewController *homeViewController = self.module.homeViewController;
    
    if ([homeViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)homeViewController;
        
        UIImage *image = [UIImage imageNamed:@"global/menu"];
        MITSlidingViewController *rootViewController = [MIT_MobileAppDelegate applicationDelegate].rootViewController;
        
        UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStyleDone target:rootViewController action:@selector(toggleViewControllerPicker:)];
        
        UIViewController *topViewController = [navigationController.viewControllers firstObject];
        [topViewController.navigationItem setLeftBarButtonItem:leftBarButtonItem];
    }
    
    self.rootViewController = homeViewController;
    
}

- (BOOL)isCurrentUserInterfaceIdiomSupported
{
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    return [self.module supportsUserInterfaceIdiom:currentUserInterfaceIdiom];
}

- (BOOL)handleURL:(NSURL *)url completion:(void (^)(void))completion
{
    NSAssert([url.scheme isEqualToString:MITInternalURLScheme],@"URL scheme must be %@",MITInternalURLScheme);

    BOOL urlWasHandled = [self.module handleLocalPath:url.path query:url.query];
    if (urlWasHandled) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (completion) {
                completion();
            }
        }];
    }
    
    return urlWasHandled;
}

- (void)setPushNotificationsEnabled:(BOOL)pushNotificationsEnabled
{
    [super setPushNotificationsEnabled:pushNotificationsEnabled];
    self.module.pushNotificationEnabled = pushNotificationsEnabled;
}

- (BOOL)canReceivePushNotifications
{
    return self.module.pushNotificationSupported;
}

- (void)didReceivePushNotification:(NSDictionary*)notification
{
    NSParameterAssert(notification);
    
    MITNotification *notificationObject = [MITUnreadNotifications addNotification:notification];
    NSAssert([notificationObject.tag isEqualToString:self.moduleItem.tag], @"notification destination tag %@ does not match module tag %@",notificationObject.tag,self.moduleItem.tag);
    [self.module handleNotification:notificationObject shouldOpen:NO];
}

@end
