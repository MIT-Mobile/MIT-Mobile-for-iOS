#import "MIT_MobileAppDelegate.h"
#import "MITModuleList.h"
#import "MITModule.h"
#import "MITDeviceRegistration.h"
#import "MITUnreadNotifications.h"
#import "AudioToolbox/AudioToolbox.h"
#import "MITSpringboard.h"
#import "DummyRotatingViewController.h"

@implementation MIT_MobileAppDelegate

@synthesize window, 
            tabBarController = theTabBarController, 
            normalNavController = theNormalNavController,
            modules,
            appModalHolder;
@synthesize deviceToken = devicePushToken;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    networkActivityRefCount = 0;
    
    NSString *navParadigmClass = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"MITNavigationParadigm"];
    if ([navParadigmClass isEqualToString:@"MITTabBarController"]) {
        navParadigm = MITNavigationParadigmTabBar;
    } else if ([navParadigmClass isEqualToString:@"MITSpringboard"]) {
        navParadigm = MITNavigationParadigmSpringboard;
    } else {
        NSLog(@"No such paradigm %@; using springboard", navParadigmClass);
        navParadigm = MITNavigationParadigmSpringboard;
    }
    
    // Initialize all modules
    self.modules = [self createModules]; // -createModules defined in ModuleListAdditions category
    
    [self registerDefaultModuleOrder];
    [self loadSavedModuleOrder];

    // Add modules to tab bar or springboard
    if (navParadigm == MITNavigationParadigmTabBar) {
        NSMutableArray *tabbedViewControllers = [[NSMutableArray alloc] initWithCapacity:[self.modules count]];
        for (MITModule *aModule in self.modules) {
            [aModule loadTabNavController];
            [tabbedViewControllers addObject:aModule.tabNavController];
        }
        theTabBarController = [[MITTabBarController alloc] initWithNibName:nil bundle:nil];
        theTabBarController.delegate = self;
        theTabBarController.viewControllers = tabbedViewControllers;
        [tabbedViewControllers release];
        [self.tabBarController updateCustomizableViewControllers:self.modules];
    }
    else {
        MITSpringboard *springboard = [[[MITSpringboard alloc] init] autorelease];
        NSMutableArray *primaryModules = [NSMutableArray array];
        for (MITModule *aModule in self.modules) {
			[primaryModules addObject:aModule];
        }
        springboard.primaryModules = [NSArray arrayWithArray:primaryModules];
        theNormalNavController = [[UINavigationController alloc] initWithRootViewController:springboard];
		theNormalNavController.delegate = springboard;
        theNormalNavController.navigationBar.barStyle = UIBarStyleBlack;
		springboard.delegate = self;
		moduleStack = [[NSMutableArray alloc] init];
    }
    
    // TODO: don't store state like this when we're using a springboard.
	// set modules state
	NSDictionary *modulesState = [[NSUserDefaults standardUserDefaults] objectForKey:MITModulesSavedStateKey];
	for (MITModule *aModule in self.modules) {
		NSDictionary *pathAndQuery = [modulesState objectForKey:aModule.tag];
		aModule.currentPath = [pathAndQuery objectForKey:@"path"];
		aModule.currentQuery = [pathAndQuery objectForKey:@"query"];
	}
	
	//APNS dictionary generated from the json of a push notificaton
	NSDictionary *apnsDict = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
	if (!apnsDict) {
		// application was not opened in response to a notification
		// so do the regular load process
		[self loadActiveModule];
	}
    
    // Set up window
    if (navParadigm == MITNavigationParadigmTabBar) {
        [self.window addSubview:theTabBarController.view];
    }
    else {
        [self.window addSubview:theNormalNavController.view];
    }
    
    appModalHolder = [[DummyRotatingViewController alloc] initWithNibName:nil bundle:nil];
    appModalHolder.canRotate = NO;
    appModalHolder.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    appModalHolder.view.userInteractionEnabled = NO;
    appModalHolder.view.hidden = YES;
    //[self.window addSubview:appModalHolder.view];

    if (navParadigm == MITNavigationParadigmSpringboard) {
        // TODO: see whether this affects horizontal flip transitions
        self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    } else {
        self.window.backgroundColor = [UIColor blackColor]; // necessary for horizontal flip transitions -- background shows through
    }
    [self.window makeKeyAndVisible];

    // Override point for customization after view hierarchy is set
    for (MITModule *aModule in self.modules) {
        [aModule applicationDidFinishLaunching];
    }

    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    // get deviceToken if it exists
    self.deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"MITDeviceToken"];
	
	[MITUnreadNotifications updateUI];
	[MITUnreadNotifications synchronizeWithMIT];
	
	// check if application was opened in response to a notofication
	if(apnsDict) {
		MITNotification *notification = [MITUnreadNotifications addNotification:apnsDict];
		[[self moduleForTag:notification.moduleName] handleNotification:notification shouldOpen:YES];
		//NSLog(@"Application opened in response to notification=%@", notification);
	}	
    
    return YES;
}

// Because we implement -application:didFinishLaunchingWithOptions: this only gets called when an mitmobile:// URL is opened from within this app
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    BOOL canHandle = NO;
    
    NSString *scheme = [url scheme];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSArray *urlTypes = [infoDict objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *type in urlTypes) {
        NSArray *schemes = [type objectForKey:@"CFBundleURLSchemes"];
        for (NSString *supportedScheme in schemes) {
            if ([supportedScheme isEqualToString:scheme]) {
                canHandle = YES;
                break;
            }
        }
        if (canHandle) {
            break;
        }
    }
    
    if (canHandle) {
        NSString *path = [url path];
        NSString *moduleTag = [url host];
        MITModule *module = [self moduleForTag:moduleTag];
        if ([path rangeOfString:@"/"].location == 0) {
            path = [path substringFromIndex:1];
        }
        
        // right now expecting URLs like mitmobile://people/search?Some%20Guy
        NSString *query = [[url query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if (!module.hasLaunchedBegun) {
            [module loadTabNavController];
            module.hasLaunchedBegun = YES;
        }
        canHandle = [module handleLocalPath:path query:query];
    } else {
        //NSLog(@"%s couldn't handle url: %@", _cmd, url);
    }

    return canHandle;
}

- (void)applicationShouldSaveState:(UIApplication *)application {
    // Let each module perform clean up as necessary
    for (MITModule *aModule in self.modules) {
        [aModule applicationWillTerminate];
    }
    
	[self saveModulesState];
    [self saveModuleOrder];
    // Save preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationShouldSaveState:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    for (MITModule *aModule in self.modules) {
        [aModule applicationDidEnterBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    for (MITModule *aModule in self.modules) {
        [aModule applicationWillEnterForeground];
    }
    [MITUnreadNotifications updateUI];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[moduleStack release];
    [self.deviceToken release];
    [self.modules release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Shared resources

- (void)showNetworkActivityIndicator {
    networkActivityRefCount++;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    NSLog(@"network indicator ++ %d", networkActivityRefCount);
}

- (void)hideNetworkActivityIndicator {
    if (networkActivityRefCount > 0) {
        networkActivityRefCount--;
//        NSLog(@"network indicator -- %d", networkActivityRefCount);
    }
    if (networkActivityRefCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//        NSLog(@"network indicator off");
    }
}

#pragma mark -
#pragma mark Tab bar delegation

- (void)tabBarController:(MITTabBarController *)tabBarController didShowItem:(UITabBarItem *)item {
    if ([tabBarController isEqual:self.tabBarController]) {
        MITModule *theModule = [self moduleForTabBarItem:item];
		// recover saved state on first appearanace
		//NSLog(@"recovering saved state for: %@  HasLaunched? %d.  Path: %@; Query: %@", theModule, theModule.hasLaunchedBegun, theModule.currentPath, theModule.currentQuery);
		if (!theModule.hasLaunchedBegun && theModule.currentPath && theModule.currentQuery) {
			[theModule handleLocalPath:theModule.currentPath query:theModule.currentQuery];
			// due to a work around implemented for the MITMoreController
			// force the view to load immediately so the chain of viewControllers is
			// the expected viewControllers
			theModule.tabNavController.topViewController.view;
		}
		theModule.hasLaunchedBegun = YES;
        [theModule didAppear];
    }
}

- (void)tabBarController:(MITTabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
    if (changed && [tabBarController isEqual:self.tabBarController]) {
        [self saveModuleOrder];
        [self.tabBarController updateCustomizableViewControllers:self.modules];
    }
}

// TODO: is this used anywhere?
/*
- (void)beginCustomizingTabs {
    [self.tabBarController.tabBar beginCustomizingItems:[self.tabBarController customizableViewControllers]];
}
*/

#pragma mark Springboard delegation

- (void)springboard:(MITSpringboard *)springboard didPushModuleForTag:(NSString *)moduleTag {
	[moduleStack addObject:moduleTag];
}

- (void)springboardDidPopModule:(MITSpringboard *)springboard {
	if (moduleStack.count) {
		[moduleStack removeLastObject];
	}
}

#pragma mark -
#pragma mark App-modal view controllers

// Call these instead of [appDelegate.tabbar presentModal...], because dismissing that crashes the app
// Also, presenting a transparent modal view controller (e.g. DatePickerViewController) the traditional way causes the screen behind to go black.
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
    appModalHolder.view.hidden = NO;
    
    if (navParadigm == MITNavigationParadigmTabBar) {
        [theTabBarController.view addSubview:appModalHolder.view];
    } else {
        [theNormalNavController.view addSubview:appModalHolder.view];
    }
    
    [appModalHolder presentModalViewController:viewController animated:animated];
}

- (void)presentRotatingAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
    appModalHolder.canRotate = YES;
    [self presentAppModalViewController:viewController animated:animated];
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {
    [appModalHolder dismissModalViewControllerAnimated:animated];
    [self performSelector:@selector(checkIfOkToHideAppModalViewController) withObject:nil afterDelay:0.100];
}

// This is a sad hack for telling when the dismissAppModalViewController animation has completed. It depends on appModalHolder.modalViewController being defined as long as the modal vc is still animating. If Apple ever changes this behavior, the slide-away transition will become a jarring pop.
- (void)checkIfOkToHideAppModalViewController {
    if (!appModalHolder.modalViewController) {
        // allow taps to reach subviews of the tabbar again
        appModalHolder.view.hidden = YES;
        appModalHolder.canRotate = NO;
        [appModalHolder.view removeFromSuperview];
    } else {
        [self performSelector:@selector(checkIfOkToHideAppModalViewController) withObject:nil afterDelay:0.100];
    }
}

- (BOOL)usesTabBar {
    return navParadigm == MITNavigationParadigmTabBar;
}

#pragma mark -
#pragma mark Push notifications

- (void)application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[MITUnreadNotifications updateUI];
	
	// vibrate the phone
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
	
	// display the notification in an alert
	UIAlertView *notificationView =[[UIAlertView alloc]
		initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]  
		message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
		delegate:[[[APNSUIDelegate alloc] initWithApnsDictionary:userInfo appDelegate:self] autorelease]
		cancelButtonTitle:@"Close"
		otherButtonTitles:@"View", nil];
	[notificationView show];
	[notificationView release];
}

- (void)application:(UIApplication *)application 
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	//NSLog(@"Registered for push notifications. deviceToken == %@", deviceToken);
    self.deviceToken = deviceToken;
    
	MITIdentity *identity = [MITDeviceRegistration identity];
	if(!identity) {
		[MITDeviceRegistration registerNewDeviceWithToken:deviceToken];
	} else {
		NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
		
		if(![oldToken isEqualToData:deviceToken]) {
			[MITDeviceRegistration newDeviceToken:deviceToken];
		}
	}
}

- (void)application:(UIApplication *)application 
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //NSLog(@"Failed to register for remote notifications. Error: %@", error);
	MITIdentity *identity = [MITDeviceRegistration identity];
	if(!identity) {
		[MITDeviceRegistration registerNewDeviceWithToken:nil];
	}
}

@end



@implementation APNSUIDelegate

- (id) initWithApnsDictionary: (NSDictionary *)apns appDelegate: (MIT_MobileAppDelegate *)delegate;
{
	self = [super init];
	if (self != nil) {
		apnsDictionary = [apns retain];
		appDelegate = [delegate retain];
		[self retain]; // releases when delegate method called
	}
	return self;
}

- (void) dealloc {
	[apnsDictionary release];
	[super dealloc];
}

// this is the delegate method for responding to the push notification UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	MITNotification *notification = [MITUnreadNotifications addNotification:apnsDictionary];
	BOOL shouldOpen = (buttonIndex == 1);
	if (shouldOpen) {
		[appDelegate dismissAppModalViewControllerAnimated:YES];
	}

	[[appDelegate moduleForTag:notification.moduleName] handleNotification:notification shouldOpen:(buttonIndex == 1)];
	
	[self release];
}

@end

