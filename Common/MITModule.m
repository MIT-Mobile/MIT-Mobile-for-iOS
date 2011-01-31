#import "MITModule.h"
#import "MITModuleList.h"
#import "Foundation+MITAdditions.h"
#import "MITTabBarItem.h"
#import "MITMoreListController.h"

@implementation MITModule

@synthesize tag, shortName, longName, iconName, tabNavController, isMovableTab, canBecomeDefault, pushNotificationSupported, pushNotificationEnabled, springboardButton;
@synthesize hasLaunchedBegun, currentPath, currentQuery;
@dynamic badgeValue, icon, tabBarIcon;

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
        self.isMovableTab = TRUE;
        self.canBecomeDefault = TRUE;
		
		// state related properties
		self.hasLaunchedBegun = NO;
		self.currentPath = nil;
		self.currentQuery = nil;
		
        self.pushNotificationSupported = NO;
        // self.pushNotificationEnabled is set in applicationDidFinishLaunching, because that's when the tag is set
        
        tabNavController = nil;
        /*
        MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate usesTabBar]) {
            
            // Give it a throwaway view controller because it cannot start with nothing.
            UIViewController *dummyVC = [[UIViewController alloc] initWithNibName:nil bundle:nil];
            dummyVC.navigationItem.title = @"Placeholder";
            tabNavController = [[UINavigationController alloc] initWithRootViewController:dummyVC];
            
            // Custom tab bar item supports having a different icon in the tab bar and the More list
            MITTabBarItem *item = [[MITTabBarItem alloc] initWithTitle:self.shortName image:self.tabBarIcon tag:0];
            tabNavController.tabBarItem = item;
            [item release];
            
            tabNavController.navigationBar.opaque = NO;
            tabNavController.navigationBar.barStyle = UIBarStyleBlack;
            
            // set overall background
            tabNavController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];	
            tabNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [dummyVC release];
            
            UIViewController *homeController = [self moduleHomeController];
            if (homeController) {
                [tabNavController setViewControllers:[NSArray arrayWithObject:[self moduleHomeController]]];
            }
            
        }
        */
    }
    return self;
}

- (void)loadTabNavController {
    if (!tabNavController) {
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Give it a throwaway view controller because it cannot start with nothing.
        UIViewController *dummyVC = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];
        dummyVC.navigationItem.title = @"Placeholder";
        tabNavController = [[UINavigationController alloc] initWithRootViewController:dummyVC];
        
        if ([appDelegate usesTabBar]) {
            // Custom tab bar item supports having a different icon in the tab bar and the More list
            MITTabBarItem *item = [[MITTabBarItem alloc] initWithTitle:self.shortName image:self.tabBarIcon tag:0];
            tabNavController.tabBarItem = item;
            [item release];
            
            tabNavController.navigationBar.opaque = NO;
            tabNavController.navigationBar.barStyle = UIBarStyleBlack;
            
            // set overall background
            tabNavController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];	
            tabNavController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        
        UIViewController *homeController = [self moduleHomeController];
        if (homeController) {
            [tabNavController setViewControllers:[NSArray arrayWithObject:[self moduleHomeController]]];
        }
    }
}

- (UIViewController *)moduleHomeController {
    // return view controller that serves as module's home screen
    NSLog(@"home controller not defined for module %@", self.tag);
    return nil;
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

    self.tabNavController.navigationItem.title = self.longName;
    MITTabBarItem *item = (MITTabBarItem *)self.tabNavController.tabBarItem;
    item.title = self.shortName;
    item.image = self.tabBarIcon;
    item.tableImage = self.icon;
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
    if ([(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] usesTabBar]) {
        return self.tabNavController.tabBarItem.badgeValue;
    } else {
        return self.springboardButton.badgeValue;
    }
}

- (void)setBadgeValue:(NSString *)newBadgeValue {
    if ([(MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate] usesTabBar]) {
        self.tabNavController.tabBarItem.badgeValue = newBadgeValue;
    } else {
        self.springboardButton.badgeValue = newBadgeValue;
    }
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

- (void)becomeActiveTab {
	if(![self isActiveTab]) {
		MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
		[appDelegate showModuleForTag:self.tag];
	}
}

- (BOOL)isActiveTab {
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	return [self.tag isEqualToString:[appDelegate activeModuleTag]];
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
	if(tabNavController.viewControllers.count > 0) {
		UIViewController *firstViewController = [tabNavController.viewControllers objectAtIndex:0];
		if(![firstViewController isKindOfClass:[MITMoreListController class]]) {
			// we only want to return a ViewController that belongs to the module
			// not More List view controller, which can be the root, for modules in the more list
			return firstViewController;
		} else if (tabNavController.viewControllers.count > 1) {
			return [tabNavController.viewControllers objectAtIndex:1];
		}
	}
	return nil;
}
		 
- (void) pushViewController: (UIViewController *)viewController {
	[[self rootViewController].navigationController pushViewController:viewController animated:NO];
}

- (UIViewController *) parentForViewController:(UIViewController *)viewController {
	UIViewController *previousViewController = nil;
	NSArray *viewControllers;
	if(tabNavController.viewControllers.count > viewController.navigationController.viewControllers.count) {
		viewControllers = tabNavController.viewControllers;
	} else {
		viewControllers = viewController.navigationController.viewControllers;
	}

	for (UIViewController *currentViewController in viewControllers) {
		if (currentViewController == viewController) {
			return previousViewController;
		}
		if (![currentViewController isKindOfClass:[MITMoreListController class]]) {
			previousViewController = currentViewController;
		}
	}
	return nil;
}

@end
