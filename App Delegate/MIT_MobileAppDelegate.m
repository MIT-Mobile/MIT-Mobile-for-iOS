
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

#import "MITTouchstoneController.h"
#import "MITSlidingViewController.h"
#import "MITLegacyModuleViewController.h"
#import "MITShuttleStopNotificationManager.h"

@interface APNSUIDelegate : NSObject <UIAlertViewDelegate>
@property (nonatomic,strong) NSDictionary *apnsDictionary;
@property (nonatomic,weak) MIT_MobileAppDelegate *appDelegate;

- (id)initWithApnsDictionary:(NSDictionary *)apns appDelegate:(MIT_MobileAppDelegate *)delegate;
@end

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate,MITTouchstoneAuthenticationDelegate>
@property (nonatomic,strong) MITTouchstoneController *sharedTouchstoneController;
@property NSInteger networkActivityCounter;

@property (nonatomic,strong) NSMutableSet *pendingNotifications;
@property(nonatomic,copy) NSArray *modules;

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

    // Needs to be set before the app continues on since there is the potential for
    // the module setup process to make things visible (for example, if there is
    //  an unread notification to process) and things will generally be very unhappy
    //  if the app attempts to make a module visible before the root view controller
    //  is told what it should care about
    NSMutableArray *moduleViewControllers = [[NSMutableArray alloc] init];
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        UIViewController<MITModuleViewControllerProtocol> *moduleViewController = [[MITLegacyModuleViewController alloc] initWithModule:module];
        NSAssert(moduleViewController.moduleItem, @"%@ is does not have a valid moduleItem",moduleViewController);
        [moduleViewControllers addObject:moduleViewController];
    }];
    
    self.rootViewController.viewControllers = moduleViewControllers;
    
    [self updateBasicServerInfo];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MITModulesSavedStateKey];

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
    // Save preferences
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[self applicationShouldSaveState:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
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
    [self.rootViewController presentViewController:viewController animated:animated completion:NULL];
}

- (void)dismissAppModalViewControllerAnimated:(BOOL)animated {    
    [self.rootViewController dismissViewControllerAnimated:animated completion:NULL];
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

- (MITSlidingViewController*)rootViewController
{
    UIViewController *rootViewController = self.window.rootViewController;
    if ([rootViewController isKindOfClass:[MITSlidingViewController class]]) {
        return (MITSlidingViewController*)rootViewController;
    } else {
        return nil;
    }
}

- (NSArray*)modules
{
    if (!_modules) {
        [self loadModules];
        NSAssert(_modules,@"failed to load application modules");
    }
    
    return _modules;
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
    NSArray *modelNames = @[@"Calendar",
                            @"CampusMap",
                            @"Dining",
                            @"Emergency",
                            @"FacilitiesLocations",
                            @"LibrariesLocationsHours",
                            @"News",
                            @"QRReaderResult",
                            @"ShuttleTrack",
                            @"MITShuttleDataModel",
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
    // Modules are listed in the order they are added here.
    NSMutableArray *modules = [[NSMutableArray alloc] init];
    
    NewsModule *newsModule = [[NewsModule alloc] init];
    [modules addObject:newsModule];
    
    ShuttleModule *shuttlesModule = [[ShuttleModule alloc] init];
    [modules addObject:shuttlesModule];
    
    CMModule *campusMapModule = [[CMModule alloc] init];
    [modules addObject:campusMapModule];
    
    CalendarModule *calendarModule = [[CalendarModule alloc] init];
    [modules addObject:calendarModule];
    
    PeopleModule *peopleModule = [[PeopleModule alloc] init];
    [modules addObject:peopleModule];
    
    ToursModule *toursModule = [[ToursModule alloc] init];
    [modules addObject:toursModule];
    
    EmergencyModule *emergencyModule = [[EmergencyModule alloc] init];
    [modules addObject:emergencyModule];
    
    LibrariesModule *librariesModule = [[LibrariesModule alloc] init];
    [modules addObject:librariesModule];
    
    FacilitiesModule *facilitiesModule = [[FacilitiesModule alloc] init];
    [modules addObject:facilitiesModule];
    
    DiningModule *diningModule = [[DiningModule alloc] init];
    [modules addObject:diningModule];
    
    QRReaderModule *qrReaderModule = [[QRReaderModule alloc] init];
    [modules addObject:qrReaderModule];
    
    LinksModule *linksModule = [[LinksModule alloc] init];
    [modules addObject:linksModule];
    
    SettingsModule *settingsModule = [[SettingsModule alloc] init];
    [modules addObject:settingsModule];
    
    AboutModule *aboutModule = [[AboutModule alloc] init];
    [modules addObject:aboutModule];
    
    _modules = modules;
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

    _remoteObjectManager = remoteObjectManager;
}


#pragma mark Application modules helper methods
- (UIViewController<MITModuleViewControllerProtocol>*)viewControllerForModuleWithTag:(NSString *)tag
{
    __block UIViewController<MITModuleViewControllerProtocol> *viewControllerForTag = nil;
    [self.moduleViewControllers enumerateObjectsUsingBlock:^(UIViewController<MITModuleViewControllerProtocol> *viewController, NSUInteger idx, BOOL *stop) {
        MITModuleItem *moduleItem = viewController.moduleItem;
        if ([moduleItem.tag isEqualToString:tag]) {
            viewControllerForTag = viewController;
            (*stop) = YES;
        }
    }];
    
    return viewControllerForTag;
}

- (void)showModuleForTag:(NSString *)tag
{
    [self showModuleForTag:tag animated:YES];
}

- (void)showModuleForTag:(NSString *)tag animated:(BOOL)animated
{
    [self.rootViewController setVisibleModuleWithTag:tag];
}

#pragma mark Preferences
- (void)saveModulesState {
    NSMutableDictionary *modulesSavedState = [NSMutableDictionary dictionary];
    /*for (MITModule *aModule in self.modules) {
        if (aModule.currentPath && aModule.currentQuery) {
            NSDictionary *moduleState = @{@"path" : aModule.currentPath,
                                          @"query" : aModule.currentQuery};
            [modulesSavedState setObject:moduleState
                                  forKey:aModule.tag];
        }
    }*/
    
    [[NSUserDefaults standardUserDefaults] setObject:modulesSavedState forKey:MITModulesSavedStateKey];
}

#pragma mark - Delegates
#pragma mark MITTouchstoneAuthenticationDelegate
- (void)touchstoneController:(MITTouchstoneController*)controller presentViewController:(UIViewController*)viewController
{
    [self.rootViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)dismissViewControllerForTouchstoneController:(MITTouchstoneController *)controller completion:(void(^)(void))completion
{
    [self.rootViewController dismissViewControllerAnimated:YES completion:completion];
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

