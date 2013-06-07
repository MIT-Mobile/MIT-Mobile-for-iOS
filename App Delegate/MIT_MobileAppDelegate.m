#import "MIT_MobileAppDelegate.h"
#import "MIT_MobileAppDelegate+Private.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"
#import "MITDeviceRegistration.h"
#import "MITUnreadNotifications.h"
#import "AudioToolbox/AudioToolbox.h"
#import "MITSpringboard.h"
#import "ModuleVersions.h"
#import "MITRotationForwardingNavigationController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "MITLogging.h"
#import "Secret.h"

@implementation MIT_MobileAppDelegate
@synthesize window,
            rootNavigationController = _rootNavigationController,
            modules;

@synthesize deviceToken = devicePushToken;

@synthesize springboardController = _springboardController,
            moduleStack = _moduleStack;

#pragma mark -
#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DDLogInfo(@"Setting default app id to '%@'", FacebookAppId);
    [FBSession setDefaultAppID:FacebookAppId];
    
#if defined(TESTFLIGHT)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop
    
    [TestFlight takeOff:@"945d1b11-83b4-40d4-b9db-3a6581b614b7"];
#endif
    
    networkActivityRefCount = 0;
    
    [self updateBasicServerInfo];
    
    // Initialize all modules
    self.modules = [self createModules]; // -createModules defined in ModuleListAdditions category
    
    [self registerDefaultModuleOrder];
    [self loadSavedModuleOrder];


    MITSpringboard *springboard = [[[MITSpringboard alloc] initWithNibName:nil bundle:nil] autorelease];
    springboard.primaryModules = [NSArray arrayWithArray:self.modules];
    springboard.delegate = self;
    
    MITRotationForwardingNavigationController *rootController = [[MITRotationForwardingNavigationController alloc] initWithRootViewController:springboard];
    rootController.delegate = springboard;
    rootController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.springboardController = springboard;
    self.rootNavigationController = rootController;
    
    // TODO: don't store state like this when we're using a springboard.
	// set modules state
	NSDictionary *modulesState = [[NSUserDefaults standardUserDefaults] objectForKey:MITModulesSavedStateKey];
	for (MITModule *aModule in self.modules) {
		NSDictionary *pathAndQuery = [modulesState objectForKey:aModule.tag];
		aModule.currentPath = [pathAndQuery objectForKey:@"path"];
		aModule.currentQuery = [pathAndQuery objectForKey:@"query"];
	}
    
    DDLogVerbose(@"Original Window size: %@ [%@]", NSStringFromCGRect([self.window frame]), self.window);
    
    if (self.window == nil)
    {
        self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
        [self.window addSubview:self.rootNavigationController.view];
        self.window.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                        UIViewAutoresizingFlexibleWidth);
    }
    else
    {
        self.window.frame = [[UIScreen mainScreen] bounds];
    }
    
    DDLogVerbose(@"Main screen size: %@ [%@]", NSStringFromCGRect([[UIScreen mainScreen] bounds]), self.window);
    [self.window setRootViewController:self.rootNavigationController];
    self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    [self.window makeKeyAndVisible];

    // Override point for customization after view hierarchy is set
    for (MITModule *aModule in self.modules) {
        [aModule applicationDidFinishLaunching];
    }

    // Register for push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    // get deviceToken if it exists
    self.deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
	
	[MITUnreadNotifications updateUI];
	[MITUnreadNotifications synchronizeWithMIT];
	
	//APNS dictionary generated from the json of a push notificaton
	NSDictionary *apnsDict = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
    
	// check if application was opened in response to a notofication
	if(apnsDict) {
		MITNotification *notification = [MITUnreadNotifications addNotification:apnsDict];
		[[self moduleForTag:notification.moduleName] handleNotification:notification shouldOpen:YES];
		DDLogVerbose(@"Application opened in response to notification=%@", notification);
	}
    
    return YES;
}

// Because we implement -application:didFinishLaunchingWithOptions: this only gets called when an mitmobile:// URL is opened from within this app
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    BOOL canHandle = NO;
    
    canHandle = [[FBSession activeSession] handleOpenURL:url];
    
    if (canHandle == NO)
    {
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
                module.hasLaunchedBegun = YES;
            }
            
            DDLogVerbose(@"handling internal url: %@", url);
            canHandle = [module handleLocalPath:path query:query];
        } else {
            DDLogWarn(@"%@ couldn't handle url: %@", NSStringFromSelector(_cmd), url);
        }
    }

    return canHandle;
}

- (void)applicationShouldSaveState:(UIApplication *)application {
    // Let each module perform clean up as necessary
    for (MITModule *aModule in self.modules) {
        [aModule applicationWillTerminate];
    }
    
	[self saveModulesState];
    
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
    self.springboardController = nil;
    self.deviceToken = nil;
    self.modules = nil;
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Shared resources

- (void)showNetworkActivityIndicator {
    networkActivityRefCount++;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    DDLogVerbose(@"network indicator ++ %d", networkActivityRefCount);
}

- (void)hideNetworkActivityIndicator {
    if (networkActivityRefCount > 0) {
        networkActivityRefCount--;
        DDLogVerbose(@"network indicator -- %d", networkActivityRefCount);
    }
    if (networkActivityRefCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        DDLogVerbose(@"network indicator off");
    }
}

#pragma mark -
#pragma mark This should probably go in another place 
- (void)updateBasicServerInfo {
    [[ModuleVersions sharedVersions] updateVersionInformation];
}

#pragma mark -
#pragma mark App-modal view controllers

// Call these instead of [appDelegate.tabbar presentModal...], because dismissing that crashes the app
// Also, presenting a transparent modal view controller (e.g. DatePickerViewController) the traditional way causes the screen behind to go black.
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.rootNavigationController.modalViewController == nil) 
    {
        [self.rootNavigationController presentModalViewController:viewController
                                                         animated:animated];
    }
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {
    if (self.rootNavigationController.modalViewController) 
    {
        [self.rootNavigationController dismissModalViewControllerAnimated:animated];
    }
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
	DDLogVerbose(@"Registered for push notifications. deviceToken == %@", deviceToken);
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
    DDLogWarn(@"%@", [error localizedDescription]);
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

