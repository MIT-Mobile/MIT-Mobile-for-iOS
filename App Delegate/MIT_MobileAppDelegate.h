#import <UIKit/UIKit.h>
#import "MITLauncherGridViewController.h"

@class MITModule;
@class MIT_MobileAppDelegate;
@class MITCoreDataController;
@class MITMobile;
@class ECSlidingViewController;

#define MITAppDelegate() ([MIT_MobileAppDelegate applicationDelegate])

@interface MIT_MobileAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic,strong) IBOutlet UIWindow *window;
@property (nonatomic,strong) NSData *deviceToken;

@property (nonatomic,readonly,copy) NSArray *modules;
@property (nonatomic,readonly,strong) UIViewController *rootViewController;

@property (nonatomic,readonly,strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic,readonly,strong) MITCoreDataController *coreDataController;
@property (nonatomic,readonly,strong) MITMobile *remoteObjectManager;
@property (nonatomic,assign,getter=isNotificationsEnabled) BOOL notificationsEnabled;

@property (nonatomic,readonly,weak) UINavigationController *topNavigationController;
@property (nonatomic,readonly,weak) ECSlidingViewController *slidingViewController;

@property (nonatomic,strong) MITLauncherGridViewController *launcherViewController;

+ (MIT_MobileAppDelegate*)applicationDelegate;

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

- (void)loadCoreDataController;
- (void)loadManagedObjectModel;
- (void)loadModules;
- (void)loadRemoteObjectManager;
- (void)loadWindow;

- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissAppModalViewControllerAnimated:(BOOL)animated;

- (MITModule *)moduleForTag:(NSString *)aTag;
- (void)showModuleForTag:(NSString *)tag;
- (void)showModuleForTag:(NSString *)tag animated:(BOOL)animated;

- (void)saveModulesState DEPRECATED_ATTRIBUTE;

- (UINavigationController*)rootNavigationController;
@end