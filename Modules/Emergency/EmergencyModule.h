#import "MITNavigationModule.h"
#import "EmergencyViewController.h"

@interface EmergencyModule : MITNavigationModule <EmergencyViewControllerDelegate>
@property(nonatomic,weak) EmergencyViewController *rootViewController;

- (instancetype)init;

@property BOOL didReadMessage DEPRECATED_ATTRIBUTE;
- (void)syncUnreadNotifications DEPRECATED_ATTRIBUTE;
@end
