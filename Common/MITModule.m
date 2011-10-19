#import "MITModule.h"
#import "MITModule+Protected.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "Foundation+MITAdditions.h"

@implementation MITModule
@synthesize tag,
            shortName, 
            longName,
            iconName,
            pushNotificationSupported,
            pushNotificationEnabled,
            springboardButton;

@synthesize hasLaunchedBegun,
            currentPath,
            currentQuery;

@dynamic badgeValue,
            isLoaded,
            moduleHomeController;

#pragma mark -
#pragma mark Required

- (id) init
{
    self = [super init];
    if (self != nil) {
        // Lazily load and prepare modules. that means:
        // Things that can wait until a module is made visible should go into a viewcontroller's -viewDidLoad or -viewWillAppear/-viewDidAppear.
        // Things that must happen at launch time go in -init -> basic properties like name and root view controller. Any loading and processing should be spawned off as an asynchronous action, in order to keep the app responsive.
        // Things that must happen at launch time but require a populated tabbar should go into -applicationDidFinishLaunching.
        
        
        self.tag = @"foo";
        self.shortName = @"foo";
        self.longName = @"Override -init!";
        self.iconName = nil;
		
		// state related properties
		self.hasLaunchedBegun = NO;
		self.currentPath = nil;
		self.currentQuery = nil;
		
        self.pushNotificationSupported = NO;
    }
    return self;
}

- (void)loadModuleHomeController
{
    DLog(@"home controller not defined for module %@", self.tag);
}


#pragma mark - Dynamic Properties
- (BOOL)isLoaded
{
    return (_moduleHomeController != nil);
}

- (void)setModuleHomeController:(UIViewController *)moduleHomeController
{
    [_moduleHomeController release];
    _moduleHomeController = [moduleHomeController retain];
}

- (UIViewController *)moduleHomeController {
    if ([self isLoaded] == NO) {
        [self loadModuleHomeController];
    }
    
    return _moduleHomeController;
}

#pragma mark -
#pragma mark Optional

- (NSString *)description {
    // put whatever you think will be helpful for debugging in here
    return [NSString stringWithFormat:@"%@, an instance of %@", self.tag, NSStringFromClass([self class])];
}

- (void)applicationDidFinishLaunching {
    // Override in subclass to perform tasks after app is setup and all modules have been instantiated.
    // Make sure to call [super applicationDidFinishLaunching]!
    // Avoid using this if possible. Use -init instead, and remember to do time consuming things in a non-blocking way.
    
    // load from disk on app start
    NSDictionary *pushDisabledSettings = [[NSUserDefaults standardUserDefaults] objectForKey:PushNotificationSettingsKey];
    self.pushNotificationEnabled = ([pushDisabledSettings objectForKey:self.tag] == nil) ? YES : NO; // enabled by default
}

- (void)applicationWillTerminate {
    // Save state if needed.
    // Don't do anything time-consuming in here.
    // Keep in mind -[MIT_MobileAppDelegate applicationWillTerminate] already writes NSUserDefaults to disk.
}

- (void)applicationDidEnterBackground {
    // stop all url loading, video playing, animations etc.
}

- (void)applicationWillEnterForeground {
    // resume interaction if needed.
}

- (void)didAppear {
    // Called whenever a module is made visible: tab tapped or entry tapped in More list.
    // If your module needs to do something whenever it appears and it doesn't make sense to do so in a view controller, override this.
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
    //NSLog(@"%@ not handling localPath: %@ query: %@", NSStringFromClass([self class]), localPath, query);
    return NO;
}

- (void)resetURL {
	self.currentPath = @"";
	self.currentQuery = @"";
}

- (BOOL)handleNotification:(MITNotification *)notification shouldOpen: (BOOL)shouldOpen {
	//NSLog(@"%@ can not handle notification %@", NSStringFromClass([self class]), notification);
	return NO;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
}

#pragma mark -
#pragma mark Use, but don't override

- (NSString *)badgeValue {
    return self.springboardButton.badgeValue;
}

- (void)setBadgeValue:(NSString *)newBadgeValue {
    self.springboardButton.badgeValue = newBadgeValue;
}

- (UIImage *)icon {
    UIImage *result = nil;
    if (self.iconName) {
        NSString *iconPath = [NSString stringWithFormat:@"%@%@%@", @"icons/module-", self.iconName, @".png"];
        result = [UIImage imageNamed:iconPath];
    }
    return result;
}

- (UIImage *)springboardIcon {
    UIImage *result = nil;
    if (self.iconName) {
        NSString *iconPath = [NSString stringWithFormat:@"%@%@%@", @"icons/home-", self.iconName, @".png"];
        result = [UIImage imageNamed:iconPath];
    }
    return result;
}

- (UIImage *)tabBarIcon {
    UIImage *result = nil;
    if (self.iconName) {
        NSString *iconPath = [NSString stringWithFormat:@"%@%@%@", @"/icons/tab-", self.iconName, @".png"];
        result = [UIImage imageNamed:iconPath];
    }
    return result;
}

- (void)becomeActiveModule {
	UIViewController *visibleController = [[MITAppDelegate() rootNavigationController] visibleViewController];
    
    if (visibleController != self.moduleHomeController)
    {
        [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
    }
}

// all notifications are enabled by default
// so we just store which modules are disabled
- (void)setPushNotificationEnabled:(BOOL)enabled; {
	NSMutableDictionary *pushDisabledSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:PushNotificationSettingsKey] mutableCopy];
	if (!pushDisabledSettings) {
        pushDisabledSettings = [[NSMutableDictionary alloc] init];
    }
    pushNotificationEnabled = enabled;
    
	if(enabled) {
		[pushDisabledSettings removeObjectForKey:self.tag];
	} else {
		[pushDisabledSettings setObject:@"disabled" forKey:self.tag];
	}
    
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	[d setObject:pushDisabledSettings forKey:PushNotificationSettingsKey];
    [d synchronize];
    [pushDisabledSettings release];
}

#pragma mark tabNavController methods
// these methods make sure to pop and push from the current UINavigationController
// which may not be the same as self.tabNavController
- (void) popToRootViewController {
	[[self rootViewController].navigationController popToViewController:[self rootViewController] animated:NO];
}

- (UIViewController *) rootViewController {
	return self.moduleHomeController;
}
		 
- (void) pushViewController: (UIViewController *)viewController {
	[[self rootViewController].navigationController pushViewController:viewController animated:NO];
}

- (UIViewController *) parentForViewController:(UIViewController *)viewController {
	UIViewController *previousViewController = nil;
	NSArray *viewControllers = viewController.navigationController.viewControllers;

	for (UIViewController *currentViewController in viewControllers) {
		if (currentViewController == viewController) {
			return previousViewController;
		}
	}
	return nil;
}

@end
