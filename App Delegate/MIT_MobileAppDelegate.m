
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
#import "MITShuttleStopNotificationManager.h"

static NSString* const MITMobileButtonTitleView = @"View";

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate,MITTouchstoneAuthenticationDelegate,UIAlertViewDelegate>
@property (nonatomic,strong) MITTouchstoneController *sharedTouchstoneController;
@property NSInteger networkActivityCounter;

@property(nonatomic,strong) NSMutableArray *pendingNotifications;
@property(nonatomic,copy) NSArray *modules;

@property (nonatomic,strong) NSRecursiveLock *lock;

- (void)updateBasicServerInfo;
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

#pragma mark -
#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if defined(TESTFLIGHT)
    if ([MITApplicationTestFlightToken length]) {
        [TestFlight setOptions:@{@"logToConsole" : @NO,
                                 @"logToSTDERR"  : @NO}];
        [TestFlight takeOff:MITApplicationTestFlightToken];
    }
#endif
    
    [[UIApplication sharedApplication]
     setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    // Default the cache expiration to 1d
    [[SDImageCache sharedImageCache] setMaxCacheAge:86400];
    
    // Create the default Touchstone controller and set it.
    // -sharedTouchstoneController is a lazy method and it should create
    // a default controller here if needed.
    [MITTouchstoneController setSharedController:self.sharedTouchstoneController];

    NSMutableArray *moduleViewControllers = [[NSMutableArray alloc] init];
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module supportsCurrentUserInterfaceIdiom]) {
            UIViewController *viewController = module.viewController;
            NSAssert(viewController, @"module %@ does not have a valid view controller",module.name);
            [moduleViewControllers addObject:viewController];
        }
    }];
    
    self.rootViewController.viewControllers = moduleViewControllers;

    [self updateBasicServerInfo];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MITModulesSavedStateKey];

    // get deviceToken if it exists
    self.deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];

    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
    } else {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }

    return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType notificationTypes = (UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound |
                                                    UIUserNotificationTypeAlert);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    }

    [MITUnreadNotifications updateUI];
    [MITUnreadNotifications synchronizeWithMIT];

    //APNS dictionary generated from the json of a push notificaton
    NSDictionary *apnsDict = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];

    [self.window makeKeyAndVisible];
    DDLogVerbose(@"Original Window size: %@ [%@]", NSStringFromCGRect([self.window frame]), self.window);

    // check if application was opened in response to a notification
    if(apnsDict) {
        [self application:[UIApplication sharedApplication] didReceiveRemoteNotification:apnsDict];
    }
    return YES;
}

// Because we implement -application:didFinishLaunchingWithOptions: this only gets called when an mitmobile:// URL is opened from within this app
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSArray *urlTypes = infoDict[@"CFBundleURLTypes"];

    __block BOOL canHandle = NO;
    [urlTypes enumerateObjectsUsingBlock:^(NSDictionary *type, NSUInteger idx, BOOL *stop) {
        NSArray *supportedSchemes = type[@"CFBundleURLSchemes"];
        [supportedSchemes enumerateObjectsUsingBlock:^(NSString *scheme, NSUInteger idx, BOOL *stop) {
            if ([scheme isEqualToString:url.scheme]) {
                canHandle = YES;
                (*stop) = YES;
            }
        }];

        (*stop) = canHandle;
    }];

    if (canHandle) {
        NSString *moduleName = url.host;
        DDLogVerbose(@"handling internal url for module %@: %@",moduleName,url);

        MITModule *module = [self moduleWithTag:moduleName];
        [module didReceiveRequestWithURL:url];

        [self.rootViewController setVisibleViewControllerWithModuleName:moduleName];
    } else {
        DDLogWarn(@"%@ couldn't handle url: %@", NSStringFromSelector(_cmd), url);
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

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [MITUnreadNotifications updateUI];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Do Nothing
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
#pragma mark Push notifications
- (BOOL)notificationsEnabled
{
    return (BOOL)[[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [self _didRecieveNotification:notification.userInfo withAlert:notification.alertBody];

    if ([application.scheduledLocalNotifications count] == 0) {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSString *message = userInfo[@"aps"][@"alert"];
    [self _didRecieveNotification:userInfo withAlert:message];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
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

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
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

- (NSMutableArray*)pendingNotifications
{
    if (!_pendingNotifications) {
        _pendingNotifications = [[NSMutableArray alloc] init];
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
    
    MITMobileResource *toursToursResource = [[MITToursResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursToursResource];
    
    MITMobileResource *toursTourResource = [[MITToursTourResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursTourResource];
    
    _remoteObjectManager = remoteObjectManager;
}

#pragma mark Private
- (void)_didRecieveNotification:(NSDictionary*)userInfo withAlert:(NSString*)alertBody
{
    [MITUnreadNotifications addNotification:userInfo];
    [MITUnreadNotifications updateUI];

    NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!applicationName) {
        applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
    }

    UIAlertView *notificationView = [[UIAlertView alloc] initWithTitle:applicationName
                                                               message:alertBody
                                                              delegate:self
                                                     cancelButtonTitle:@"Close"
                                                     otherButtonTitles:MITMobileButtonTitleView, nil];
    [notificationView show];
}

#pragma mark Application modules helper methods
- (MITModule*)moduleWithTag:(NSString *)tag
{
    __block MITModule *selectedModule = nil;
    [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
        if ([module.name isEqualToString:tag]) {
            selectedModule = module;
            (*stop) = YES;
        }
    }];
    
    return selectedModule;
}

- (void)showModuleWithTag:(NSString *)tag
{
    [self showModuleWithTag:tag animated:NO];
}

- (void)showModuleWithTag:(NSString *)tag animated:(BOOL)animated
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",MITInternalURLScheme,tag]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark Preferences
- (void)saveModulesState {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:MITModulesSavedStateKey];
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

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSDictionary *remoteNotification = [self.pendingNotifications lastObject];
    [self.pendingNotifications removeLastObject];

    MITNotification *notification = [MITUnreadNotifications addNotification:remoteNotification];
    MITModule *module = [self moduleWithTag:notification.moduleName];
    [module didReceiveNotification:remoteNotification];

    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:MITMobileButtonTitleView]) {
        [self.rootViewController setVisibleViewControllerWithModuleName:module.name];
    }
}

@end
