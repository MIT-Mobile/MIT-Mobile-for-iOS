#import "ECSlidingViewController.h"

@class MITNotification;
@class MITModuleViewController;

@interface MITSlidingViewController : UIViewController
@property(nonatomic,weak) IBOutlet ECSlidingViewController *slidingViewController;
@property(nonatomic,copy) NSString *slidingViewControllerStoryboardId;

@property(nonatomic,readonly,strong) UIBarButtonItem *leftBarButtonItem;

@property(nonatomic,copy) NSArray *viewControllers;
@property(nonatomic,weak) UIViewController *visibleViewController;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;

- (void)setVisibleViewControllerWithModuleName:(NSString*)name;

- (void)showModuleSelector:(BOOL)animated completion:(void(^)(void))block;
- (void)hideModuleSelector:(BOOL)animated completion:(void(^)(void))block;
@end
