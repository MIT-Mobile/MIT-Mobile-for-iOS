#import "ECSlidingViewController.h"
#import "UIViewController+MITDrawerNavigation.h"

@class MITModule;

@interface MITRootViewController : ECSlidingViewController
@property (nonatomic,copy) NSArray *modules;
@property (nonatomic,weak) MITModule *visibleModule;

- (instancetype)initWithModules:(NSArray*)modules;

- (void)setVisibleModuleWithTag:(NSString*)moduleTag;
- (BOOL)setVisibleModuleWithNotification:(MITNotification*)notification;
- (BOOL)setVisibleModuleWithURL:(NSURL*)url;
@end
