#import "MITSlidingAnimationController.h"
#import "ECSlidingConstants.h"

@interface MITSlidingAnimationController ()
@property(nonatomic,copy) void (^coordinatorAnimations)(id<UIViewControllerTransitionCoordinatorContext>context);
@property(nonatomic,copy) void (^coordinatorCompletion)(id<UIViewControllerTransitionCoordinatorContext>context);
@end

@implementation MITSlidingAnimationController
@synthesize operation = _operation;
@synthesize slidingViewController = _slidingViewController;

- (instancetype)initWithSlidingViewController:(ECSlidingViewController *)slidingViewController operation:(ECSlidingViewControllerOperation)operation
{
    self = [super init];
    if (self) {
        _slidingViewController = slidingViewController;
        _operation = operation;
    }

    return self;
}

#pragma mark - Delegation
#pragma mark ECSlidingViewControllerLayout
- (CGRect)slidingViewController:(ECSlidingViewController *)slidingViewController frameForViewController:(UIViewController *)viewController topViewPosition:(ECSlidingViewControllerTopViewPosition)topViewPosition
{
    CGRect frame = CGRectInfinite;

    if (viewController == slidingViewController.underLeftViewController) {
        frame = slidingViewController.view.bounds;
        frame.size.width -= slidingViewController.anchorRightPeekAmount;
    }

    return frame;
}

#pragma mark UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    if (_defaultTransitionDuration) {
        return _defaultTransitionDuration;
    } else {
        return 0.25;
    }
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *topViewController = [transitionContext viewControllerForKey:ECTransitionContextTopViewControllerKey];
    UIViewController *toViewController  = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    CGRect topViewInitialFrame = [transitionContext initialFrameForViewController:topViewController];
    CGRect topViewFinalFrame   = [transitionContext finalFrameForViewController:topViewController];
    
    topViewController.view.frame = topViewInitialFrame;
    
    if (topViewController != toViewController) {
        CGRect toViewFinalFrame = [transitionContext finalFrameForViewController:toViewController];
        toViewController.view.frame = toViewFinalFrame;
        [containerView insertSubview:toViewController.view belowSubview:topViewController.view];
    }
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        if (self.coordinatorAnimations) self.coordinatorAnimations((id<UIViewControllerTransitionCoordinatorContext>)transitionContext);
        topViewController.view.frame = topViewFinalFrame;
    } completion:^(BOOL finished) {
        if ([transitionContext transitionWasCancelled]) {
            topViewController.view.frame = [transitionContext initialFrameForViewController:topViewController];
        }
        
        if (self.coordinatorCompletion) self.coordinatorCompletion((id<UIViewControllerTransitionCoordinatorContext>)transitionContext);
        [transitionContext completeTransition:finished];
    }];
}

@end
