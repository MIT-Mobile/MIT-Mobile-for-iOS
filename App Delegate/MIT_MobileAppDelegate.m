
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "MITDeviceRegistration.h"
#import "MITUnreadNotifications.h"
#import "AudioToolbox/AudioToolbox.h"
#import "ModuleVersions.h"
#import "MITLogging.h"
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
#import "MITScannerModule.h"
#import "SettingsModule.h"
#import "ShuttleModule.h"
#import "ToursModule.h"
#import "MITMobiusModule.h"

#import "MITTouchstoneController.h"
#import "MITSlidingViewController.h"
#import "MITShuttleStopNotificationManager.h"
#import "MITShuttleController.h"

static NSString* const MITMobileButtonTitleView = @"View";
static NSString* const MITMobileLastActiveModuleNameKey = @"MITMobileLastActiveModuleName";

@interface MIT_MobileAppDelegate () <UINavigationControllerDelegate,MITTouchstoneAuthenticationDelegate,UIAlertViewDelegate,MITSlidingViewControllerDelegate >
@property (nonatomic,strong) MITTouchstoneController *sharedTouchstoneController;
@property NSInteger networkActivityCounter;

@property(nonatomic,strong) NSMutableArray *pendingNotifications;

@property(nonatomic,copy) NSString *lastActiveModuleName;
@property(nonatomic,copy) NSArray *modules;

@property (nonatomic,strong) NSRecursiveLock *lock;

- (void)updateBasicServerInfo;
@end

@implementation MIT_MobileAppDelegate
@synthesize coreDataController = _coreDataController;
@synthesize remoteObjectManager = _remoteObjectManager;
@synthesize managedObjectModel = _managedObjectModel;
@dynamic lastActiveModuleName;

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

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

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

    self.rootViewController.delegate = self;
    self.rootViewController.viewControllers = moduleViewControllers;

    NSString *activeModuleName = self.lastActiveModuleName;
    if (activeModuleName) {
        MITModule *module = [self moduleWithTag:self.lastActiveModuleName];
        if (module && (module.viewController.moduleItem.type == MITModulePresentationFullScreen)) {
            self.rootViewController.visibleViewController = module.viewController;
        }
    }

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

    [[MITShuttleController sharedController] loadDefaultShuttleRoutes];

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

    [self addGlobalMITStyling];
    
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

        [self showModuleWithTag:module.name animated:YES];
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
            DDLogWarn(@"unmatched number of calls to showNetworkActivityIndicator: %ld", (long)count);
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
		[MITDeviceRegistration registerNewDeviceWithToken:deviceToken completion:^(BOOL success) {
            [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
                if (module.pushNotificationSupported) {
                    [self _registerNotificationsForModuleWithName:module.name enabled:success completed:nil];
                }
            }];
        }];
	} else {
		NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:DeviceTokenKey];

		if(![oldToken isEqualToData:deviceToken]) {
			[MITDeviceRegistration newDeviceToken:deviceToken completion:^(BOOL success) {
                [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
                    if (module.pushNotificationSupported) {
                        [self _registerNotificationsForModuleWithName:module.name enabled:success completed:nil];
                    }
                }];
            }];
        } else {
            [self.modules enumerateObjectsUsingBlock:^(MITModule *module, NSUInteger idx, BOOL *stop) {
                if (module.pushNotificationSupported) {
                    [self _registerNotificationsForModuleWithName:module.name enabled:YES completed:nil];
                }
            }];
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
                            @"News",
                            @"QRReaderResult",
                            @"MITShuttleDataModel",
                            @"PeopleDataModel",
                            @"MITToursDataModel",
                            @"Mobius"];

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

    DiningModule *diningModule = [[DiningModule alloc] init];
    [modules addObject:diningModule];
    
    FacilitiesModule *facilitiesModule = [[FacilitiesModule alloc] init];
    [modules addObject:facilitiesModule];

    MITScannerModule *scannerModule = [[MITScannerModule alloc] init];
    [modules addObject:scannerModule];
    
    MITMobiusModule *martyModule = [[MITMobiusModule alloc] init];
    [modules addObject:martyModule];

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
    
    MITMobileResource *mapObjectPlaces = [[MITMapObjectResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:mapObjectPlaces];

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

    MITMobileResource *librariesUserResource = [[MITLibrariesUserResource alloc] init];
    [remoteObjectManager addResource:librariesUserResource];

    MITMobileResource *librariesMITIdentityResource = [[MITLibrariesMITIdentityResource alloc] init];
    [remoteObjectManager addResource:librariesMITIdentityResource];

    MITMobileResource *librariesItemDetailResource = [[MITLibrariesItemDetailResource alloc] init];
    [remoteObjectManager addResource:librariesItemDetailResource];

    MITMobileResource *toursToursResource = [[MITToursResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursToursResource];

    MITMobileResource *toursTourResource = [[MITToursTourResource alloc] initWithManagedObjectModel:self.managedObjectModel];
    [remoteObjectManager addResource:toursTourResource];

    MITMobileResource *emergencyInfoContactResource = [[MITEmergencyInfoContactsResource alloc] init];
    [remoteObjectManager addResource:emergencyInfoContactResource];
    
    MITMobileResource *emergencyInfoAnnouncementResource =[[MITEmergencyInfoAnnouncementResource alloc] init];
    [remoteObjectManager addResource:emergencyInfoAnnouncementResource];
    
    _remoteObjectManager = remoteObjectManager;
}

#pragma mark Private
- (void)_didRecieveNotification:(NSDictionary*)userInfo withAlert:(NSString*)alertBody
{
    MITNotification *notification = [MITUnreadNotifications addNotification:userInfo];
    [MITUnreadNotifications updateUI];

    NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!applicationName) {
        applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
    }

    [self.pendingNotifications addObject:notification];
    UIAlertView *notificationView = [[UIAlertView alloc] initWithTitle:applicationName
                                                               message:alertBody
                                                              delegate:self
                                                     cancelButtonTitle:@"Close"
                                                     otherButtonTitles:MITMobileButtonTitleView, nil];
    [notificationView show];
}

- (void)_registerNotificationsForModuleWithName:(NSString*)name enabled:(BOOL)enabled completed:(void (^)(void))block
{
    // If we don't have an identity, don't even try to enable (or disable) notifications,
    // just leave everything as-is
    if (!self.deviceToken) {
        if (block) {
            block();
        }

        return;
    } else {
        NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
        parameters[@"module_name"] = name;
        parameters[@"enabled"] = (enabled ? @"1" : @"0");

        NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:@"moduleSetting" parameters:parameters];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
        [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *registrationResult) {
            if (![registrationResult isKindOfClass:[NSDictionary class]]) {
                DDLogError(@"fatal error: invalid response for push configuration");
            } else if (registrationResult[@"error"]) {
                DDLogError(@"failed to enable notifications for module %@ with error %@",name,registrationResult[@"error"]);
            }

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block();
                }
            }];
        } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
            DDLogError(@"failed to enable notifications for module %@ with error %@",name,error);

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block();
                }
            }];
        }];

        [[NSOperationQueue mainQueue] addOperation:requestOperation];
    }
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
    MITModule *module = [self moduleWithTag:tag];

    UIViewController *viewController = module.viewController;
    [self.rootViewController setVisibleViewController:viewController animated:animated completion:^{
        if (viewController.moduleItem.type == MITModulePresentationFullScreen) {
            self.lastActiveModuleName = module.name;
        }
    }];
}

#pragma mark Preferences
- (void)saveModulesState {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:MITModulesSavedStateKey];
}

- (void)setLastActiveModuleName:(NSString *)lastActiveModuleName
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];

    DDLogVerbose(@"updating last presented module from '%@' to '%@'",self.lastActiveModuleName,lastActiveModuleName);
    
    if (lastActiveModuleName) {
        [standardUserDefaults setObject:lastActiveModuleName forKey:MITMobileLastActiveModuleNameKey];
    } else {
        [standardUserDefaults removeObjectForKey:MITMobileLastActiveModuleNameKey];
    }
}

- (NSString*)lastActiveModuleName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:MITMobileLastActiveModuleNameKey];
}

#pragma mark - Delegates
#pragma mark MITTouchstoneAuthenticationDelegate
- (void)touchstoneController:(MITTouchstoneController*)controller presentViewController:(UIViewController*)viewController completion:(void(^)(void))completion
{
    UIViewController *rootViewController = [self.window rootViewController];
    UIViewController *presented = [rootViewController presentedViewController];

    if (UIUserInterfaceIdiomPad == [UIDevice currentDevice].userInterfaceIdiom) {
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    } else {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }

    if (presented) {
        [presented presentViewController:viewController animated:YES completion:completion];
    } else {
        [rootViewController presentViewController:viewController animated:YES completion:completion];
    }
}

- (void)touchstoneController:(MITTouchstoneController*)controller dismissViewController:(UIViewController*)viewController completion:(void(^)(void))completion
{
    UIViewController *rootViewController = [self.window rootViewController];
    UIViewController *presented = [rootViewController presentedViewController];

    if (presented) {
        [presented dismissViewControllerAnimated:YES completion:completion];
    } else {
        [rootViewController dismissViewControllerAnimated:YES completion:completion];
    }
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    MITNotification *notification = [self.pendingNotifications lastObject];
    [self.pendingNotifications removeLastObject];

    MITModule *module = [self moduleWithTag:notification.moduleName];
    [module didReceiveNotification:notification.userInfo];

    NSString *activeModuleName = self.rootViewController.visibleViewController.moduleItem.name;
    if ([activeModuleName isEqualToString:notification.moduleName]) {
        [MITUnreadNotifications removeNotificationsForModuleTag:notification.moduleName];
    }

    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:MITMobileButtonTitleView]) {
        [self showModuleWithTag:module.name animated:YES];
    }
}

#pragma mark MITSlidingViewControllerDelegate
- (void)slidingViewController:(MITSlidingViewController *)slidingViewController didShowTopViewController:(UIViewController *)viewController
{
    MITModuleItem *moduleItem = viewController.moduleItem;
    if (moduleItem.type == MITModulePresentationFullScreen) {
        self.lastActiveModuleName = moduleItem.name;
    }

    [MITUnreadNotifications removeNotificationsForModuleTag:moduleItem.name];
}

#pragma mark - Global App Styling
- (void)addGlobalMITStyling
{
    [[UINavigationBar appearance] setTintColor:[UIColor mit_tintColor]];
    [[UITableViewCell appearance] setTintColor:[UIColor mit_tintColor]];
    [[UISegmentedControl appearance] setTintColor:[UIColor mit_tintColor]];
    [[UIToolbar appearance] setBarTintColor:[UIColor mit_navBarColor]];
    [[UITableView appearance] setSectionIndexColor:[UIColor mit_tintColor]];
}

@end
