#import <FacebookSDK/FacebookSDK.h>

#import "MIT_MobileAppDelegate.h"
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
#import "UIKit+MITAdditions.h"

// CoreData persistence and Mobile API access
#import "MITCoreDataController.h"
#import "CoreDataManager.h"
#import "MITMobile.h"
#import "MITMapPlacesResource.h"
#import "MITMapCategoriesResource.h"

// Module headers
#import "AboutModule.h"
#import "CalendarModule.h"
#import "CMModule.h"
#import "DiningModule.h"
#import "EmergencyModule.h"
#import "FacilitiesModule.h"
#import "LibrariesModule.h"
#import "LinksModule.h"
#import "MITMobileServerConfiguration.h"
#import "NewsModule.h"
#import "PeopleModule.h"
#import "QRReaderModule.h"
#import "SettingsModule.h"
#import "ShuttleModule.h"
#import "ToursModule.h"

@interface APNSUIDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic,strong) NSDictionary *apnsDictionary;
@property (nonatomic,weak) MIT_MobileAppDelegate *appDelegate;

- (id)initWithApnsDictionary:(NSDictionary *)apns appDelegate:(MIT_MobileAppDelegate *)delegate;
@end

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate>
@property NSInteger networkActivityCounter;

- (void)updateBasicServerInfo;
@end

@implementation MIT_MobileAppDelegate {
    MITCoreDataController *_coreDataController;
    NSManagedObjectModel *_managedObjectModel;
    NSArray *_modules;
    MITMobile *_remoteObjectManager;
}

@dynamic coreDataController,managedObjectModel,modules,remoteObjectManager;

+ (void)initialize
{
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
}

+ (MIT_MobileAppDelegate*)applicationDelegate
{
    id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];

    if ([appDelegate isKindOfClass:[MIT_MobileAppDelegate class]]) {
        return (MIT_MobileAppDelegate*)appDelegate;
    } else {
        return nil;
    }
}

+ (MITModule*)moduleForTag:(NSString *)aTag
{
    return [[self applicationDelegate] moduleForTag:aTag];
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
    
    // The below load* methods called here are not necessary.
    //  The property getters are lazy and will load in the proper order.
    //  This is done to clearly illustrate the order in which they
    //  should be setup.
    [self loadManagedObjectModel];
    [self loadCoreDataController];
    [self loadRemoteObjectManager];
    
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

#pragma mark -
#pragma mark App-modal view controllers

// Call these instead of [appDelegate.tabbar presentModal...], because dismissing that crashes the app
// Also, presenting a transparent modal view controller (e.g. DatePickerViewController) the traditional way causes the screen behind to go black.
- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.rootNavigationController.presentedViewController == nil)
    {
        [self.rootNavigationController presentViewController:viewController animated:animated completion:NULL];
    }
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {
    if (self.rootNavigationController.presentedViewController)
    {
        [self.rootNavigationController dismissViewControllerAnimated:animated completion:NULL];
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

#pragma mark - Lazy property getters
- (MITMobile*)remoteObjectManager
{
    if (!_remoteObjectManager) {
        [self loadRemoteObjectManager];
        NSAssert(_remoteObjectManager, @"failed to initalize the persitence stack");
    }

    return _remoteObjectManager;
}

- (NSManagedObjectModel*)managedObjectModel
{
    if (!_managedObjectModel) {
        [self loadManagedObjectModel];
        NSAssert(_managedObjectModel, @"failed to create the managed object model");
    }

    return _managedObjectModel;
}

- (MITCoreDataController*)coreDataController
{
    if (!_coreDataController) {
        [self loadCoreDataController];
        NSAssert(_coreDataController, @"failed to load CoreData store controller");
    }

    return _coreDataController;
}

- (UIWindow*)window
{
    if (!_window) {
        [self loadWindow];
        NSAssert(_window, @"failed to load main window");
    }
    
    return _window;
}

- (NSArray*)modules
{
    if (!_modules) {
        [self loadModules];
        NSAssert(_modules,@"failed to load application modules");
    }
    
    return _modules;
}

#pragma mark Property load methods
- (void)loadCoreDataController
{
    _coreDataController = [[MITCoreDataController alloc] initWithManagedObjectModel:self.managedObjectModel];
}

- (void)loadManagedObjectModel
{
    NSArray *modelNames = @[@"Calendar",
                            @"CampusMap",
                            @"Dining",
                            @"Emergency",
                            @"FacilitiesLocations",
                            @"LibrariesLocationsHours",
                            @"News",
                            @"QRReaderResult",
                            @"ShuttleTrack",
                            @"Tours",
                            @"PeopleDataModel"];
    
    NSMutableArray *managedObjectModels = [[NSMutableArray alloc] init];
    [modelNames enumerateObjectsUsingBlock:^(NSString *modelName, NSUInteger idx, BOOL *stop) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"momd"];
        NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        NSAssert(objectModel, @"managed object model '%@' at URL '%@' could not be loaded",modelName,modelURL);
        
        [managedObjectModels addObject:objectModel];
    }];
    
    _managedObjectModel = [NSManagedObjectModel modelByMergingModels:managedObjectModels];
}

- (void)loadModules {
    // add your MITModule subclass here by adding it to the below
    _modules = @[[[NewsModule alloc] init],
                 [[ShuttleModule alloc] init],
                 [[CMModule alloc] init],
                 [[CalendarModule alloc] init],
                 [[PeopleModule alloc] init],
                 [[ToursModule alloc] init],
                 [[EmergencyModule alloc] init],
                 [[LibrariesModule alloc] init],
                 [[FacilitiesModule alloc] init],
                 [[DiningModule alloc] init],
                 [[QRReaderModule alloc] init],
                 [[LinksModule alloc] init],
                 [[SettingsModule alloc] init],
                 [[AboutModule alloc] init]];
}

- (void)loadRemoteObjectManager
{
    MITMobile *remoteObjectManager = [[MITMobile alloc] init];
    [remoteObjectManager setManagedObjectStore:self.coreDataController.managedObjectStore];
    
    MITMobileResource *mapPlaces = [[MITMapPlacesResource alloc] initWithPathPattern:MITMobileMapPlaces managedObjectModel:self.managedObjectModel];
    [remoteObjectManager setResource:mapPlaces forName:MITMobileMapPlaces];
    
    MITMobileResource *mapCategories = [[MITMapCategoriesResource alloc] initWithPathPattern:MITMobileMapCategories managedObjectModel:self.managedObjectModel];
    [remoteObjectManager setResource:mapCategories forName:MITMobileMapCategories];
    
    _remoteObjectManager = remoteObjectManager;
}

- (void)loadWindow
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor mit_backgroundColor];
    
    // iOS 6's UIWindow doesn't do tintColor
    if ([window respondsToSelector:@selector(setTintColor:)]) {
        window.tintColor = [UIColor colorWithHexString:@"a90533"]; // MIT Red, aka Pantone 201
    }
    
    DDLogVerbose(@"Root window size is %@", NSStringFromCGRect([window bounds]));
    
    MITSpringboard *springboard = [[MITSpringboard alloc] init];
    springboard.primaryModules = self.modules;
    self.springboardController = springboard;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:springboard];
    navigationController.navigationBarHidden = NO;
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.navigationBar.translucent = NO;
    navigationController.delegate = self;
    self.rootNavigationController = navigationController;
    
    window.rootViewController = navigationController;
    self.window = window;
}

#pragma mark Application modules helper methods
- (MITModule *)moduleForTag:(NSString *)aTag {
    for (MITModule *aModule in self.modules) {
        if ([aModule.tag isEqual:aTag]) {
            return aModule;
        }
    }
    return nil;
}

- (void)showModuleForTag:(NSString *)tag {
    [self.springboardController pushModuleWithTag:tag];
}

#pragma mark Preferences
- (void)saveModulesState {
	NSMutableDictionary *modulesSavedState = [NSMutableDictionary dictionary];
    for (MITModule *aModule in self.modules) {
		if (aModule.currentPath && aModule.currentQuery) {
            NSDictionary *moduleState = @{@"path" : aModule.currentPath,
                                          @"query" : aModule.currentQuery};
            [modulesSavedState setObject:moduleState
                                  forKey:aModule.tag];
		}
	}
    
	[[NSUserDefaults standardUserDefaults] setObject:modulesSavedState forKey:MITModulesSavedStateKey];
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

