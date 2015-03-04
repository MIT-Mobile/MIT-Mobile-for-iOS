#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ECSlidingViewController/ECSlidingViewController.h>

@interface MITSlidingAnimationController : NSObject <UIViewControllerAnimatedTransitioning,ECSlidingViewControllerLayout>
@property(nonatomic,weak,readonly) ECSlidingViewController *slidingViewController;
@property(nonatomic,readonly) ECSlidingViewControllerOperation operation;
@property(nonatomic) NSTimeInterval defaultTransitionDuration;

- (instancetype)initWithSlidingViewController:(ECSlidingViewController*)slidingViewController operation:(ECSlidingViewControllerOperation)operation;

@end
