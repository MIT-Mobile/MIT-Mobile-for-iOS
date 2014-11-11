#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "MITDeviceRegistration.h"
#import "MITUnreadNotifications.h"
#import "AudioToolbox/AudioToolbox.h"
#import "ModuleVersions.h"
#import "MITLogging.h"
#import "Secret.h"
#import "SDImageCache.h"
#import "MITNavigationController.h"

// CoreData persistence and Mobile API access
#import "MITAdditions.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"

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

#import "ECSlidingViewController.h"
#import "MITTouchstoneController.h"

#import "MITLauncher.h"
#import "MITLauncherGridViewController.h"
#import "MITLauncherListViewController.h"

#import "MITShuttleStopNotificationManager.h"

@interface APNSUIDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic,strong) NSDictionary *apnsDictionary;
@property (nonatomic,weak) MIT_MobileAppDelegate *appDelegate;

- (id)initWithApnsDictionary:(NSDictionary *)apns appDelegate:(MIT_MobileAppDelegate *)delegate;
@end

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate,MITTouchstoneAuthenticationDelegate,MITLauncherDataSource,MITLauncherDelegate>
@property (nonatomic,strong) MITLauncherGridViewController *launcherViewController;

@property (nonatomic,strong) MITTouchstoneController *sharedTouchstoneController;
@property NSInteger networkActivityCounter;
@property (nonatomic,strong) NSMutableSet *pendingNotifications;

@property (nonatomic,weak) MITModule *activeModule;
@property (nonatomic,strong) NSMutableArray *mutableModules;
@property (nonatomic,strong) NSMutableDictionary *viewControllersByTag;

@property (nonatomic,strong) NSRecursiveLock *lock;

- (void)updateBasicServerInfo;
- (void)showModuleForTagUsingPadIdiom:(NSString*)tag animated:(BOOL)animated;
- (void)showModuleForTagUsingPhoneIdiom:(NSString*)tag animated:(BOOL)animated;
@end

@implementation MIT_MobileAppDelegate {
    MITCoreDataController *_coreDataController;
    NSManagedObjectModel *_managedObjectModel;
    MITMobile *_remoteObjectManager;
}

@synthesize rootViewController = _rootViewController;
@dynamic coreDataController,managedObjectModel,remoteObjectManager;

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

#warning Ross: I added this because the header declares it, but it wasn't implemented, and was causing crashes.
- (UINavigationController*)rootNavigationController {
    return nil;
}

#pragma mark -
#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if defined(TESTFLIGHT)
    if ([MITApplicationTestFlightToken length]) {
        [TestFlight setOptions:@{@"logToConsole" : @NO,
                                 @"logToSTDERR"  : @NO}];
        [TestFlight takeOff:MITApplicationTestFlightToken];
    }
#endif
    
    // Default the cache expiration to 1d
    [[SDImageCache sharedImageCache] setMaxCacheAge:86400];
    
    // Create the default Touchstone controller and set it.
    // -sharedTouchstoneController is a lazy method and it should create
    // a default controller here if needed.
    [MITTouchstoneController setSharedController:self.sharedTouchstoneController];
    
    [self updateBasicServerInfo];
    
    // TODO: don't store state like this when we're using a springboard.
	// set modules state
	NSDictionary *modulesState = [[NSUserDefaults standardUserDefaults] objectForKey:MITModulesSavedStateKey];
	for (MITModule *aModule in self.modules) {
		NSDictionary *pathAndQuery = modulesState[aModule.tag];
		aModule.currentPath = pathAndQuery[@"path"];
		aModule.currentQuery = pathAndQuery[@"query"];
	}
    
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
    DDLogVerbose(@"Original Window size: %@ [%@]", NSStringFromCGRect([self.window frame]), self.window);
    
    return YES;
}

// Because we implement -application:didFinishLaunchingWithOptions: this only gets called when an mitmobile:// URL is opened from within this app
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    BOOL canHandle = NO;
    
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
    [self.window.rootViewController presentViewController:viewController animated:animated completion:NULL];
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {    
    [self.window.rootViewController dismissViewControllerAnimated:animated completion:NULL];
}

#pragma mark -
#pragma mark Push notifications
- (BOOL)notificationsEnabled
{
    return (BOOL)[[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[MITUnreadNotifications updateUI];
	
	// vibrate the phone
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
	
	// display the notification in an alert
    APNSUIDelegate *notificationHelper = [[APNSUIDelegate alloc] initWithApnsDictionary:userInfo appDelegate:self];
    [self.pendingNotifications addObject:notificationHelper];
    
	UIAlertView *notificationView =[[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                              message:userInfo[@"aps"][@"alert"]
                                                             delegate:notificationHelper
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

#pragma mark - Local Notifications

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[[UIAlertView alloc] initWithTitle:@"Alert" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

    if ([application.scheduledLocalNotifications count] == 0) {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
}

#pragma mark - Background Fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([application.scheduledLocalNotifications count] > 0) {
        [[MITShuttleStopNotificationManager sharedManager] performBackgroundNotificationUpdatesWithCompletion:^(NSError *error) {
            if (error) {
                completionHandler(UIBackgroundFetchResultFailed);
            } else {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }];
    } else {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

#pragma mark - Lazy property getters
- (NSRecursiveLock*)lock
{
    if (!_lock) {
        @synchronized([self class]) {
            if (!_lock) {
                _lock = [[NSRecursiveLock alloc] init];
            }
        }
    }
    
    return _lock;
}

- (MITTouchstoneController*)sharedTouchstoneController
{
    [self.lock lock];
    
    if (!_sharedTouchstoneController) {
        [self loadTouchstoneController];
        NSAssert(_sharedTouchstoneController && [MITTouchstoneController sharedController], @"failed to load Touchstone authentication controller");
    }
    
    [self.lock unlock];
    
    return _sharedTouchstoneController;
}

- (MITMobile*)remoteObjectManager
{
    [self.lock lock];
    
    if (!_remoteObjectManager) {
        
        [self loadRemoteObjectManager];
        NSAssert(_remoteObjectManager, @"failed to initalize the persitence stack");
    }
    
    [self.lock unlock];
    
    return _remoteObjectManager;
}

- (NSManagedObjectModel*)managedObjectModel
{
    [self.lock lock];
    
    if (!_managedObjectModel) {
        [self loadManagedObjectModel];
        NSAssert(_managedObjectModel, @"failed to create the managed object model");
    }
    
    [self.lock unlock];
    
    return _managedObjectModel;
}

- (MITCoreDataController*)coreDataController
{
    [self.lock lock];
    
    if (!_coreDataController) {
        [self loadCoreDataController];
        NSAssert(_coreDataController, @"failed to load CoreData store controller");
    }
    
    [self.lock unlock];
    
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

- (UIViewController*)rootViewController
{
    UIUserInterfaceIdiom *userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    return [self rootViewControllerForUserInterfaceIdiom:userInterfaceIdiom];
}

- (NSArray*)modules
{
    if (!_mutableModules) {
        [self loadModules];
        NSAssert(_mutableModules,@"failed to load application modules");
    }
    
    return [NSArray arrayWithArray:_mutableModules];
}

- (NSMutableSet*)pendingNotifications
{
    if (!_pendingNotifications) {
        _pendingNotifications = [[NSMutableSet alloc] init];
    }
    
    return _pendingNotifications;
}

#pragma mark Property load methods
- (void)loadTouchstoneController
{
    MITTouchstoneController *touchstoneController = [[MITTouchstoneController alloc] init];
    touchstoneController.authenticationDelegate = self;
    self.sharedTouchstoneController = touchstoneController;
    [MITTouchstoneController setSharedController:touchstoneController];
}

- (void)loadCoreDataController
{
    _coreDataController = [[MITCoreDataController alloc] initWithManagedObjectModel:self.managedObjectModel];
}

- (void)loadManagedObjectModel
{
    NSArray *modelNames = @[@"MITCalendarDataModel",
                            @"CampusMap",
                            @"MITDiningDataModel",
                            @"Emergency",
                            @"FacilitiesLocations",
                            @"LibrariesLocationsHours",
                            @"News",
                            @"QRReaderResult",
                            @"MITShuttleDataModel",
                            @"Tours",
                            @"PeopleDataModel",
                            @"MITToursDataModel"];
    
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
    // Modules are listed in the order they are added here. If two modules are
    // added with the same tag, the first module will be removed and then the
    // second module will be added.
    _mutableModules = [[NSMutableArray alloc] init];
    
    NewsModule *newsModule = [[NewsModule alloc] init];
    [self registerModule:newsModule];
    
    ShuttleModule *shuttlesModule = [[ShuttleModule alloc] init];
    [self registerModule:shuttlesModule];
    
    CMModule *campusMapModule = [[CMModule alloc] init];
    [self registerModule:campusMapModule];
    
    CalendarModule *calendarModule = [[CalendarModule alloc] init];
    [self registerModule:calendarModule];
    
    PeopleModule *peopleModule = [[PeopleModule alloc] init];
    [self registerModule:peopleModule];
    
    ToursModule *toursModule = [[ToursModule alloc] init];
    [self registerModule:toursModule];
    
    EmergencyModule *emergencyModule = [[EmergencyModule alloc] init];
    [self registerModule:emergencyModule];
    
    LibrariesModule *librariesModule = [[LibrariesModule alloc] init];
    [self registerModule:librariesModule];
    
    FacilitiesModule *facilitiesModule = [[FacilitiesModule alloc] init];
    [self registerModule:facilitiesModule];
    
    DiningModule *diningModule = [[DiningModule alloc] init];
    [self registerModule:diningModule];
    
    QRReaderModule *qrReaderModule = [[QRReaderModule alloc] init];
    [self registerModule:qrReaderModule];
    
    LinksModule *linksModule = [[LinksModule alloc] init];
    [self registerModule:linksModule];
    
    SettingsModule *settingsModule = [[SettingsModule alloc] init];
    [self registerModule:settingsModule];
    
    AboutModule *aboutModule = [[AboutModule alloc] init];
    [self registerModule:aboutModule];
}

- (void)loadRemoteObjectManager
{
    MITMobile *remoteObjectManager = [[MITMobile alloc] init];
    [remoteObjectManager setManagedObjectStore:self.coreDataController.managedObjectStore];
    
    MITMobileResource *mapPlaces = [[MITMapPlacesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:mapPlaces];
    
    MITMobileResource *mapCategories = [[MITMapCategoriesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:mapCategories];
    
    MITMobileResource *newsStories = [[MITNewsStoriesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:newsStories];
    
    MITMobileResource *newsCategories = [[MITNewsCategoriesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:newsCategories];
    
    MITMobileResource *personResource = [[MITPersonResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:personResource];
    
    MITMobileResource *peopleResource = [[MITPeopleResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:peopleResource];
    
    MITMobileResource *shuttleRoutesResource = [[MITShuttleRoutesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:shuttleRoutesResource];
    
    MITMobileResource *shuttleRouteDetailResource = [[MITShuttleRouteDetailResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:shuttleRouteDetailResource];

    MITMobileResource *shuttleStopDetailResource = [[MITShuttleStopDetailResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:shuttleStopDetailResource];

    MITMobileResource *shuttlePredictionsResource = [[MITShuttlePredictionsResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:shuttlePredictionsResource];

    MITMobileResource *shuttleVehiclesResource = [[MITShuttleVehiclesResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:shuttleVehiclesResource];
    
    MITMobileResource *calendarsCalendarsResource = [[MITCalendarsCalendarsResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:calendarsCalendarsResource];

    MITMobileResource *calendarsCalendarResource = [[MITCalendarsCalendarResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:calendarsCalendarResource];
    
    MITMobileResource *calendarsEventsResource = [[MITCalendarsEventsResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:calendarsEventsResource];
    
    MITMobileResource *calendarsEventResource = [[MITCalendarsEventResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:calendarsEventResource];
    
    MITMobileResource *diningResource = [[MITDiningResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:diningResource];
    
    MITMobileResource *librariesResource = [[MITLibrariesResource alloc] init];
    [remoteObjectManager addResource:librariesResource];
    
    MITMobileResource *librariesLinksResource = [[MITLibrariesLinksResource alloc] init];
    [remoteObjectManager addResource:librariesLinksResource];
    
    MITMobileResource *librariesAskUsResource = [[MITLibrariesAskUsResource alloc] init];
    [remoteObjectManager addResource:librariesAskUsResource];
    
    MITMobileResource *librariesSearchResource = [[MITLibrariesSearchResource alloc] init];
    [remoteObjectManager addResource:librariesSearchResource];
    
    MITMobileResource *librariesItemDetailResource = [[MITLibrariesItemDetailResource alloc] init];
    [remoteObjectManager addResource:librariesItemDetailResource];
    
    MITMobileResource *toursToursResource = [[MITToursResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursToursResource];
    
    MITMobileResource *toursTourResource = [[MITToursTourResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursTourResource];
    
    _remoteObjectManager = remoteObjectManager;
}

- (void)loadWindow
{
    DDLogVerbose(@"creating window for application frame %@", NSStringFromCGRect([[UIScreen mainScreen] applicationFrame]));
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor mit_backgroundColor];
    
    // iOS 6's UIWindow doesn't do tintColor
    if ([window respondsToSelector:@selector(setTintColor:)]) {
        window.tintColor = [UIColor mit_tintColor];
    }
    
    UIUserInterfaceIdiom const userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
    window.rootViewController = [self rootViewControllerForUserInterfaceIdiom:userInterfaceIdiom];
    
//    UINavigationController *navigationController = [[MITNavigationController alloc] initWithRootViewController:window.rootViewController];
//    navigationController.delegate = self;
//    self.rootNavigationController = navigationController;
    
    self.window = window;
}

- (UIViewController*)createRootViewControllerForPadIdiom
{
    MITLauncherListViewController *launcherViewController = [[MITLauncherListViewController alloc] init];
    launcherViewController.dataSource = self;
    launcherViewController.delegate = self;
    
    NSString *logoName;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        logoName = @"global/navbar_mit_logo_light";
    } else {
        logoName = @"global/navbar_mit_logo_dark";
        launcherViewController.edgesForExtendedLayout = (UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom);
    }
    
    UIImage *logoView = [UIImage imageNamed:logoName];
    launcherViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:logoView];
    launcherViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    
    UIViewController *topViewController = [[UIViewController alloc] init];
    topViewController.view.backgroundColor = [UIColor mit_backgroundColor];
    
    UINavigationController *navigationController = [[MITNavigationController alloc] initWithRootViewController:topViewController];
    navigationController.navigationBarHidden = NO;
    navigationController.toolbarHidden = YES;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        navigationController.navigationBar.barStyle = UIBarStyleDefault;
        navigationController.navigationBar.translucent = YES;
    } else {
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
        navigationController.navigationBar.translucent = NO;
    }
    
    navigationController.delegate = self;
    
    ECSlidingViewController *slidingViewController = [[ECSlidingViewController alloc] initWithTopViewController:navigationController];
    slidingViewController.underLeftViewController = launcherViewController;
    slidingViewController.anchorRightRevealAmount = 280.;
    
    UISwipeGestureRecognizer *gestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(anchorRight)];
    gestureRecognizer.numberOfTouchesRequired = 2;
    gestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [navigationController.view addGestureRecognizer:gestureRecognizer];
    
    _topNavigationController = navigationController;
    _slidingViewController = slidingViewController;
    
    MITModule *topModule = [self.modules firstObject];
    [self showModuleForTag:topModule.tag];
    
    return slidingViewController;
}

- (UINavigationController*)createRootViewControllerForPhoneIdiom
{
    MITLauncherGridViewController *launcherViewController = [[MITLauncherGridViewController alloc] init];
    launcherViewController.dataSource = self;
    launcherViewController.delegate = self;
    
    NSString *logoName;
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        logoName = @"global/navbar_mit_logo_light";
    } else {
        logoName = @"global/navbar_mit_logo_dark";
    }
    
    UIImage *logoView = [UIImage imageNamed:logoName];
    launcherViewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:logoView];
    launcherViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    UINavigationController *navigationController = [[MITNavigationController alloc] initWithRootViewController:launcherViewController];
    navigationController.navigationBarHidden = NO;
    navigationController.toolbarHidden = YES;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        navigationController.navigationBar.barStyle = UIBarStyleDefault;
        navigationController.navigationBar.translucent = YES;
    } else {
        navigationController.navigationBar.barStyle = UIBarStyleBlack;
        navigationController.navigationBar.translucent = NO;
    }
    
    navigationController.delegate = self;
    
    _topNavigationController = navigationController;
    return navigationController;
}

#pragma mark Application modules helper methods
- (UIViewController*)rootViewControllerForUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
{
    if (!_rootViewController) {
        if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            _rootViewController = [self createRootViewControllerForPadIdiom];
        } else if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            _rootViewController = [self createRootViewControllerForPhoneIdiom];
        }
    }
    
    return _rootViewController;
}

- (void)registerModule:(MITModule*)module
{
    NSString *tag = module.tag;
    
    if (!tag) {
        return;
    } else if ([module supportsUserInterfaceIdiom:[[UIDevice currentDevice] userInterfaceIdiom]]) {
        MITModule *oldModule = [self moduleForTag:tag];
        if (oldModule) {
            [self.mutableModules removeObject:oldModule];
        }
        
        if (module) {
            [self.mutableModules addObject:module];
        }
    }
}

- (MITModule *)moduleForTag:(NSString *)tag
{
    __block MITModule *moduleForTag = nil;
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module.tag isEqualToString:tag]) {
            moduleForTag = module;
            (*stop) = YES;
        }
    }];
    
    return moduleForTag;
}

- (UIViewController*)homeViewControllerForModuleWithTag:(NSString*)tag
{
    UIViewController *viewController = self.viewControllersByTag[tag];
 
    if (!_viewControllersByTag) {
        self.viewControllersByTag = [[NSMutableDictionary alloc] init];
    }
    
    if (!viewController) {
        MITModule *module = [self moduleForTag:tag];
        viewController = [module homeViewControllerForUserInterfaceIdiom:[[UIDevice currentDevice] userInterfaceIdiom]];
        
        if (viewController) {
            self.viewControllersByTag[tag] = viewController;
        }
    }
    
    return viewController;
}

- (void)showModuleForTag:(NSString *)tag
{
    [self showModuleForTag:tag animated:YES];
}

- (void)showModuleForTag:(NSString *)tag animated:(BOOL)animated
{
    MITModule *module = [self moduleForTag:tag];
    
    if (module) {
        UIUserInterfaceIdiom const userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
        if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self showModuleForTagUsingPadIdiom:tag animated:animated];
        } else if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [self showModuleForTagUsingPhoneIdiom:tag animated:animated];
        } else {
            NSString *reason = [NSString stringWithFormat:@"unknown user interface idiom %d",userInterfaceIdiom];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }
    }
}

- (void)showModuleForTagUsingPadIdiom:(NSString*)tag animated:(BOOL)animated
{
    MITModule *module = [self moduleForTag:tag];
    
    if (!module) {
        DDLogWarn(@"failed to show module: no registered module for tag %@",tag);
        return;
    }
    
    void (^showModuleBlock)(void) = ^{
        if (self.topNavigationController) {
            UIViewController *homeViewController = [self homeViewControllerForModuleWithTag:tag];
            
            UIImage *barButtonIcon = [UIImage imageNamed:@"global/menu"];
            UIBarButtonItem *anchorLeftButton = [[UIBarButtonItem alloc] initWithImage:barButtonIcon style:UIBarButtonItemStylePlain target:self action:@selector(anchorRight:)];
            homeViewController.navigationItem.leftBarButtonItem = anchorLeftButton;
            
            self.activeModule = module;
            if (self.topNavigationController.topViewController == homeViewController) {
                // Absolutely nothing to do, just exit here
                return;
            } else if ([self.topNavigationController.viewControllers containsObject:homeViewController]) {
                [self.topNavigationController popToViewController:homeViewController animated:animated];
            } else {
                [self.topNavigationController popToRootViewControllerAnimated:NO];
                [self.topNavigationController pushViewController:homeViewController animated:YES];
            }
            
        }
    };
    
    if (self.slidingViewController && (self.slidingViewController.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered)) {
        [self.slidingViewController resetTopViewAnimated:YES onComplete:^{
            showModuleBlock();
        }];
    } else {
        showModuleBlock();
    }
}

- (void)showModuleForTagUsingPhoneIdiom:(NSString*)tag animated:(BOOL)animated
{
    MITModule *module = [self moduleForTag:tag];
    
    if (!module) {
        DDLogWarn(@"failed to show module: no registered module for tag %@",tag);
        return;
    }
    
    if (self.topNavigationController) {
        UIViewController *homeViewController = [self homeViewControllerForModuleWithTag:tag];
        
        if ([self.topNavigationController.viewControllers containsObject:homeViewController]) {
            [self.topNavigationController popToViewController:homeViewController animated:animated];
        } else {
            [self.topNavigationController popToRootViewControllerAnimated:NO];
            [self.topNavigationController pushViewController:homeViewController animated:animated];
        }
        
        self.activeModule = module;
    }
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

#pragma mark - UIActions
- (IBAction)anchorRight:(id)sender
{
    UIViewController *rootViewController = self.rootViewController;
    if ([rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *slidingViewController = (ECSlidingViewController*)rootViewController;
        [slidingViewController anchorTopViewToRightAnimated:YES];
    }
}
#pragma mark - Delegates
#pragma mark MITTouchstoneAuthenticationDelegate
- (void)touchstoneController:(MITTouchstoneController*)controller presentViewController:(UIViewController*)viewController
{
    UIViewController *rootViewController = [self.window rootViewController];
    UIViewController *presented = [rootViewController presentedViewController];
    if (presented) {
        [presented presentViewController:viewController animated:YES completion:nil];
    } else {
        [rootViewController presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)dismissViewControllerForTouchstoneController:(MITTouchstoneController *)controller completion:(void(^)(void))completion
{
    UIViewController *rootViewController = [self.window rootViewController];
    UIViewController *presented = [rootViewController presentedViewController];
    if (presented) {
        [presented dismissViewControllerAnimated:NO completion:nil];
    } else {
        [rootViewController dismissViewControllerAnimated:NO completion:nil];
    }
}


#pragma mark MITLauncherDataSource
- (NSUInteger)numberOfItemsInLauncher:(MITLauncherGridViewController *)launcher
{
    return [self.modules count];
}

- (MITModule*)launcher:(MITLauncherGridViewController *)launcher moduleAtIndexPath:(NSIndexPath *)index
{
    return self.modules[index.row];
}

#pragma mark MITLauncherDelegate
- (void)launcher:(MITLauncherGridViewController *)launcher didSelectModuleAtIndexPath:(NSIndexPath *)indexPath
{
    MITModule *module = self.modules[indexPath.row];
    [self showModuleForTag:module.tag];
}

@end


@implementation APNSUIDelegate
- (id)initWithApnsDictionary: (NSDictionary *)apns appDelegate: (MIT_MobileAppDelegate *)delegate;
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.appDelegate.pendingNotifications removeObject:self];
}

@end

