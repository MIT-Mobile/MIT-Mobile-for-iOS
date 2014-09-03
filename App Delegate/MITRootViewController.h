#import "ECSlidingViewController.h"
#import "UIViewController+MITDrawerNavigation.h"

@class MITModule;

@interface MITRootViewController : ECSlidingViewController
@property (nonatomic,copy) NSArray *modules;

@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic,weak) MITModule *selectedModule;

- (instancetype)initWithModules:(NSArray*)modules;
- (BOOL)showModuleForNotification:(MITNotification*)notification;
- (BOOL)showModuleForURL:(NSURL*)url;
@end
