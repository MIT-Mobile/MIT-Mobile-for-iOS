#import "MITSpringboard.h"

@class MITModule;
@class MIT_MobileAppDelegate;

#define MITAppDelegate() ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate])

@interface MIT_MobileAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, weak) UINavigationController *rootNavigationController;
@property (nonatomic, weak) MITSpringboard *springboardController;
@property (nonatomic, copy) NSArray *modules;
@property (nonatomic, strong) NSData *deviceToken;

+ (MIT_MobileAppDelegate*)applicationDelegate;

- (void)showNetworkActivityIndicator;
- (void)hideNetworkActivityIndicator;

- (void)presentAppModalViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)dismissAppModalViewControllerAnimated:(BOOL)animated;
@end