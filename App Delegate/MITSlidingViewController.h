#import "ECSlidingViewController.h"

@class MITNotification;
@class MITModuleViewController;

@protocol MITSlidingViewControllerDelegate <ECSlidingViewControllerDelegate,NSObject>
@optional
- (void)slidingViewController:(MITSlidingViewController*)slidingViewController willHideTopViewController:(UIViewController*)viewController;
- (void)slidingViewController:(MITSlidingViewController*)slidingViewController didShowTopViewController:(UIViewController*)viewController;
@end

@interface MITSlidingViewController : ECSlidingViewController
@property(nonatomic,readonly,strong) UIBarButtonItem *leftBarButtonItem;

@property(nonatomic,copy) NSArray *viewControllers;
@property(nonatomic,weak) UIViewController *visibleViewController;
@property(nonatomic,weak) id<MITSlidingViewControllerDelegate> delegate;

- (instancetype)initWithViewControllers:(NSArray*)viewControllers;

- (void)setVisibleViewControllerWithModuleName:(NSString*)name;

- (void)showModuleSelector:(BOOL)animated completion:(void(^)(void))block;
- (void)hideModuleSelector:(BOOL)animated completion:(void(^)(void))block;
@end
