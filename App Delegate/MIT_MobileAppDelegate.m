#import <FacebookSDK/FacebookSDK.h>

#import "MIT_MobileAppDelegate.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITModule.h"
#import "MITDeviceRegistration.h"
#import "MITUnreadNotifications.h"
#import "AudioToolbox/AudioToolbox.h"
#import "MITSpringboard.h"
#import "ModuleVersions.h"
#import "MITLogging.h"
#import "Secret.h"
#import "SDImageCache.h"
#import "Foundation+MITAdditions.h"

@interface APNSUIDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic,strong) NSDictionary *apnsDictionary;
@property (nonatomic,weak) MIT_MobileAppDelegate *appDelegate;

- (id)initWithApnsDictionary:(NSDictionary *)apns appDelegate:(MIT_MobileAppDelegate *)delegate;
@end

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate>
@property NSInteger networkActivityCounter;

- (void)loadWindow;
- (void)updateBasicServerInfo;
@end

@implementation MIT_MobileAppDelegate
+ (void)initialize
{
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
}

#pragma mark -
#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if defined(TESTFLIGHT)
    if ([MITApplicationTestFlightToken length]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
        #pragma clang diagnostic pop
        
        [TestFlight setOptions:@{@"logToConsole" : @NO,
                                 @"logToSTDERR"  : @NO}];
        [TestFlight takeOff:MITApplicationTestFlightToken];
    }
#endif
    [FBSession setDefaultAppID:FacebookAppId];

    // Default the cache expiration to 1d
    [[SDImageCache sharedImageCache] setMaxCacheAge:86400];
    
    [self updateBasicServerInfo];
    
    // Initialize all modules
    [self loadModules];

    // TODO: don't store state like this when we're using a springboard.
	// set modules state
	NSDictionary *modulesState = [[NSUserDefaults standardUserDefaults] objectForKey:MITModulesSavedStateKey];
	for (MITModule *aModule in self.modules) {
		NSDictionary *pathAndQuery = modulesState[aModule.tag];
		aModule.currentPath = pathAndQuery[@"path"];
		aModule.currentQuery = pathAndQuery[@"query"];
	}
    
    [self loadWindow];
    DDLogVerbose(@"Original Window size: %@ [%@]", NSStringFromCGRect([self.window frame]), self.window);

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
	NSDictionary *apnsDict = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    
	// check if application was opened in response to a notofication
	if(apnsDict) {
		MITNotification *notification = [MITUnreadNotifications addNotification:apnsDict];
		[[self moduleForTag:notification.moduleName] handleNotification:notification shouldOpen:YES];
		DDLogVerbose(@"Application opened in response to notification=%@", notification);
	}
    
    [self.window makeKeyAndVisible];
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
        NSArray *urlTypes = infoDict[@"CFBundleURLTypes"];
        for (NSDictionary *type in urlTypes) {
            NSArray *schemes = type[@"CFBundleURLSchemes"];
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // (https://developers.facebook.com/docs/tutorials/ios-sdk-tutorial/authenticate - 2013.07.17)
    // We need to properly handle activation of the application with regards to Facebook Login
    // (e.g., returning from iOS 6.0 Login Dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

#pragma mark - Shared resources
- (void)showNetworkActivityIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger count = self.networkActivityCounter + 1;
        
        if (count < 1) {
            DDLogWarn(@"unmatched number of calls to showNetworkActivityIndicator: %d",count);
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        self.networkActivityCounter = count;
    });
}

- (void)hideNetworkActivityIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger count = self.networkActivityCounter - 1;
        
        if (count < 1) {
            count = 0;
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            self.networkActivityCounter = count;
        }
    });
}

#pragma mark - Class Extension Methods
// TODO: This may not belong here.
- (void)updateBasicServerInfo
{
    [[ModuleVersions sharedVersions] updateVersionInformation];
}

- (void)loadWindow
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    DDLogVerbose(@"Root window size is %@", NSStringFromCGRect([self.window bounds]));

    MITSpringboard *springboard = [[MITSpringboard alloc] init];
    springboard.primaryModules = self.modules;
    self.springboardController = springboard;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:springboard];
    navigationController.navigationBarHidden = NO;
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.navigationBar.translucent = NO;
    navigationController.delegate = self;
    self.rootNavigationController = navigationController;
    
    self.window.rootViewController = navigationController;
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
	UIAlertView *notificationView =[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                              message:userInfo[@"aps"][@"alert"]
                                                             delegate:[[APNSUIDelegate alloc] initWithApnsDictionary:userInfo appDelegate:self]
                                                    cancelButtonTitle:@"Close"
                                                    otherButtonTitles:@"View", nil];
	[notificationView show];
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

    if ([error code] == 3010) {
        // Running the simulator and, since the simulator can't register for notifications
        // just kill our device ID so a nil identity is returned whenever we are asked
        [MITDeviceRegistration clearIdentity];
    } else {
        // Something odd happened but create a new identity anyway (if needed) and register it with the
        // notification server just in case.
        MITIdentity *identity = [MITDeviceRegistration identity];
        if(!identity) {
            [MITDeviceRegistration registerNewDeviceWithToken:nil];
        }
    }
}

@end


@implementation APNSUIDelegate
- (id) initWithApnsDictionary: (NSDictionary *)apns appDelegate: (MIT_MobileAppDelegate *)delegate;
{
	self = [super init];
	if (self != nil) {
		_apnsDictionary = apns;
		_appDelegate = delegate;
	}
    
	return self;
}

// this is the delegate method for responding to the push notification UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	MITNotification *notification = [MITUnreadNotifications addNotification:self.apnsDictionary];
	BOOL shouldOpen = (buttonIndex == 1);
	if (shouldOpen) {
		[self.appDelegate dismissAppModalViewControllerAnimated:YES];
	}

	[[self.appDelegate moduleForTag:notification.moduleName] handleNotification:notification shouldOpen:(buttonIndex == 1)];
}

@end

