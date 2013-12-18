#import "MITSpringboard.h"

@class MITModule;
@class MIT_MobileAppDelegate;
@class MITCoreDataController;
@class MITMobile;

#define MITAppDelegate() ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate])

@interface MIT_MobileAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic,strong) IBOutlet UIWindow *window;
@property (nonatomic,weak) UINavigationController *rootNavigationController;
@property (nonatomic,weak) MITSpringboard *springboardController;
@property (nonatomic,strong) NSData *deviceToken;

@property (nonatomic,readonly) NSArray *modules;
@property (nonatomic,readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic,readonly) MITCoreDataController *coreDataController;
@property (nonatomic,readonly) MITMobile *remoteObjectManager;

+ (MIT_MobileAppDelegate*)applicationDelegate;
+ (MITModule *)moduleForTag:(NSString *)aTag DEPRECATED_ATTRIBUTE;

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
- (void)saveModulesState;
@end