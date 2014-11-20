#import <UIKit/UIKit.h>

@class MITSlidingViewController;
@class MITModule;
@class MIT_MobileAppDelegate;
@class MITCoreDataController;
@class MITMobile;

@protocol MITModuleViewControllerProtocol;

#define MITAppDelegate() ((MIT_MobileAppDelegate*)[[UIApplication sharedApplication] delegate])

@interface UIApplication (MITMobileAppDelegate)
@property(nonatomic,weak) MIT_MobileAppDelegate *delegate;
@end

@interface MIT_MobileAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) IBOutlet UIWindow *window;
@property(nonatomic,strong) NSData *deviceToken;

@property(nonatomic,readonly) IBOutlet MITSlidingViewController *rootViewController;
@property(nonatomic,readonly,copy) NSArray *modules;

@property(nonatomic,readonly,strong) NSManagedObjectModel *managedObjectModel;
@property(nonatomic,readonly,strong) MITCoreDataController *coreDataController;
@property(nonatomic,readonly,strong) MITMobile *remoteObjectManager;
@property(nonatomic,assign,getter=isNotificationsEnabled) BOOL notificationsEnabled;


+ (MIT_MobileAppDelegate*)applicationDelegate;

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

- (void)loadCoreDataController;
- (void)loadManagedObjectModel;
- (void)loadModules;
- (void)loadRemoteObjectManager;

- (MITModule*)moduleWithTag:(NSString *)aTag;
- (void)showModuleWithTag:(NSString *)tag;
- (void)showModuleWithTag:(NSString *)tag animated:(BOOL)animated;
@end