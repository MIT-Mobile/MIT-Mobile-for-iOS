#import "MITModule.h"

#import "Foundation+MITAdditions.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

@interface MITModule ()

@end

@implementation MITModule
@synthesize moduleHomeController = _moduleHomeController;

#pragma mark -
- (instancetype)init
{
    return [self initWithTag:nil];
}

- (instancetype)initWithTag:(NSString *)tag
{
    self = [super init];
    if (self) {
        _tag = [tag copy];
    }

    return self;
}

#pragma mark Setting up the module's main view controller
- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    if (idiom == UIUserInterfaceIdiomPhone) {
        if ([self respondsToSelector:@selector(loadModuleHomeController)]) {
            return YES;
        }
    }
    
    return NO;
}

- (UIViewController*)homeViewController
{
    return [self homeViewControllerForUserInterfaceIdiom:[[UIDevice currentDevice] userInterfaceIdiom]];
}

- (UIViewController*)homeViewControllerForUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    if (idiom == UIUserInterfaceIdiomPad) {
        return [self createHomeViewControllerForPadIdiom];
    } else if (idiom == UIUserInterfaceIdiomPhone) {
        return [self createHomeViewControllerForPhoneIdiom];
    } else {
        return nil;
    }
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return nil;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    if ([self respondsToSelector:@selector(loadModuleHomeController)]) {
        return self.moduleHomeController;
    } else {
        return nil;
    }
}

- (UIViewController*)moduleHomeController
{
    if (!_moduleHomeController) {
        if ([self respondsToSelector:@selector(loadModuleHomeController)]) {
            [self loadModuleHomeController];
        } else {
            UIUserInterfaceIdiom const userInterfaceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
            _moduleHomeController = [self homeViewControllerForUserInterfaceIdiom:userInterfaceIdiom];
        }
        
        NSAssert(_moduleHomeController,@"failed to create home UIViewController for module %@",self.tag);
    }

    return _moduleHomeController;
}

- (void)loadModuleHomeController
{
    _moduleHomeController = nil;
    return;
}

#pragma mark Handling Notifications
- (void)setPushNotificationEnabled:(BOOL)enabled completion:(void (^)(void))block
{
    _pushNotificationEnabled = enabled;
/*
    MITModule *module = [MITAppDelegate() moduleForTag:tag];
    NSMutableDictionary *parameters = [[MITDeviceRegistration identity] mutableDictionary];
    parameters[@"module_name"] = tag;
    parameters[@"enabled"] = (enabled ? @"1" : @"0");

    NSURLRequest *request = [NSURLRequest requestForModule:@"push"
                                                   command:@"moduleSetting"
                                                parameters:parameters
                                                    method:@"GET"];

    // If we don't have an identity, don't even try to enable (or disable) notifications,
    // just leave everything as-is
    if (!self.canRegisterForNotifications) {
        if (block) {
            block();
        }

        return;
    } else {

        MobileRequestOperation *request = [[MobileRequestOperation alloc] initWithModule:@"push"
                                                                                 command:@"moduleSetting"
                                                                              parameters:parameters];
        request.completeBlock = ^(MobileRequestOperation *operation, NSDictionary *jsonResult, NSString *contentType, NSError *error) {
            if (![jsonResult isKindOfClass:[NSDictionary class]]) {
                DDLogError(@"fatal error: invalid response for push configuration");
            } else if ([jsonResult[@"success"] boolValue]) {
                module.pushNotificationEnabled = [jsonResult[@"enabled"] boolValue];
            } else {
                if (error) {
                    [UIAlertView alertViewForError:error withTitle:@"Settings" alertViewDelegate:nil];
                } else if (jsonResult[@"error"]) {
                    DDLogError(@"%@ notifications change request failed: %@",tag,error);
                }
            }

            if (block) {
                block();
            }
        };

        [[MobileRequestOperation defaultQueue] addOperation:request];
    }*/
}


#pragma mark
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ <%@>",self.tag,_homeViewController];
}

- (void)applicationDidFinishLaunching
{
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
    DDLogWarn(@"%@ not handling localPath: %@ query: %@", NSStringFromClass([self class]), localPath, query);
    return NO;
}

- (void)resetURL {
	self.currentPath = @"";
	self.currentQuery = @"";
}

- (BOOL)handleNotification:(MITNotification *)notification shouldOpen: (BOOL)shouldOpen {
	DDLogWarn(@"%@ can not handle notification %@", NSStringFromClass([self class]), notification);
	return NO;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
}

#pragma mark Internals
- (UIImage *)icon
{
    NSString *iconPath = [NSString stringWithFormat:@"%@%@%@", @"icons/module-", self.iconName, @".png"];
    return [UIImage imageNamed:iconPath];
}

- (UIImage *)springboardIcon
{
    NSString *iconPath = [NSString stringWithFormat:@"%@%@%@", @"icons/home-", self.iconName, @".png"];
    return [UIImage imageNamed:iconPath];
}

@end
