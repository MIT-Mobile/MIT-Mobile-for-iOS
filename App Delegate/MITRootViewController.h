#import "ECSlidingViewController.h"
#import "UIViewController+MITDrawerNavigation.h"

@interface MITRootViewController : ECSlidingViewController
@property (nonatomic,copy) NSArray *viewControllers;

@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic,weak) UIViewController *selectedViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;
@end
