#import "MITScaleAnimationController.h"
#import "ECSlidingViewController.h"

typedef NS_ENUM(NSUInteger, MITScaleAnimationState) {
    MITScaleAnimationStart,
    MITScaleAnimationEnd
};

@interface MITScaleAnimationController ()
@property (nonatomic) ECSlidingViewControllerOperation operation;
@property (nonatomic) CGFloat scaleFactor;
@end

@implementation MITScaleAnimationController
- (instancetype)initWithOperation:(ECSlidingViewControllerOperation)operation scaleFactor:(CGFloat)scaleFactor {
    self = [super init];

    if (self) {
        _operation = operation;
        _scaleFactor = scaleFactor;
    }

    return self;
}

#pragma mark - ECSlidingViewControllerLayout
- (CGRect)slidingViewController:(ECSlidingViewController *)slidingViewController
         frameForViewController:(UIViewController *)viewController
                topViewPosition:(ECSlidingViewControllerTopViewPosition)topViewPosition {
    if (viewController == slidingViewController.topViewController) {
        if (topViewPosition == ECSlidingViewControllerTopViewPositionAnchoredRight) {
            return [self finalFrameForTopViewAnchoredRight:slidingViewController];
        }
    }

    return CGRectInfinite;
}

#pragma mark - UIViewControllerAnimatedTransitioning
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.33;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *topViewController = [transitionContext viewControllerForKey:ECTransitionContextTopViewControllerKey];
    UIViewController *leftDrawerViewController  = [transitionContext viewControllerForKey:ECTransitionContextUnderLeftControllerKey];
    UIView *containerView = [transitionContext containerView];

    UIView *topView = topViewController.view;
    topView.frame = containerView.bounds;

    UIView *leftDrawerView = leftDrawerViewController.view;
    leftDrawerView.layer.transform = CATransform3DIdentity;

    NSTimeInterval duration = [self transitionDuration:transitionContext];
    CGFloat springVelocity = 0;
    CGFloat springDamping = 0.85;

    switch (self.operation) {
        case ECSlidingViewControllerOperationAnchorRight: {
            // Ensure the left drawer view is positioned underneath the top view
            [containerView insertSubview:leftDrawerViewController.view belowSubview:topView];

            [self configureTopView:topView withState:MITScaleAnimationStart frame:containerView.bounds];
            [self configureLeftDrawerView:leftDrawerViewController.view withState:MITScaleAnimationStart frame:containerView.bounds];

            [UIView animateWithDuration:duration
                                  delay:0.
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:springVelocity
                                options:0
                             animations:^{
                                 [self configureLeftDrawerView:leftDrawerView
                                                     withState:MITScaleAnimationEnd
                                                         frame:CGRectNull];
                                 [self configureTopView:topView
                                              withState:MITScaleAnimationEnd
                                                  frame:[transitionContext finalFrameForViewController:topViewController]];
                                 [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                             } completion:^(BOOL finished) {
                                 if ([transitionContext transitionWasCancelled]) {
                                     leftDrawerView.frame = [transitionContext finalFrameForViewController:leftDrawerViewController];
                                     leftDrawerView.alpha = 1;

                                     [self configureTopView:topView withState:MITScaleAnimationStart frame:containerView.bounds];
                                     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                                 }

                                 [transitionContext completeTransition:finished];
                             }];
        } break;

        case ECSlidingViewControllerOperationResetFromRight: {
            [self configureTopView:topView withState:MITScaleAnimationEnd frame:[transitionContext initialFrameForViewController:topViewController]];
            [self configureLeftDrawerView:leftDrawerView withState:MITScaleAnimationEnd frame:CGRectNull];

            [UIView animateWithDuration:duration
                                  delay:0.
                 usingSpringWithDamping:springDamping
                  initialSpringVelocity:springVelocity
                                options:0
                             animations:^{
                                 [self configureLeftDrawerView:leftDrawerView
                                                     withState:MITScaleAnimationStart
                                                         frame:containerView.bounds];

                                 [self configureTopView:topView
                                              withState:MITScaleAnimationStart
                                                  frame:containerView.bounds];
                                 [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                             } completion:^(BOOL finished) {
                                 if ([transitionContext transitionWasCancelled]) {
                                     leftDrawerView.frame = [transitionContext finalFrameForViewController:leftDrawerViewController];
                                     leftDrawerView.alpha = 1;

                                     [self configureTopView:topView withState:MITScaleAnimationStart frame:containerView.bounds];
                                     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                                 }

                                 [transitionContext completeTransition:finished];
                             }];
        } break;

        default:
            break;
    }
}


- (CGRect)finalFrameForTopViewAnchoredRight:(ECSlidingViewController*)slidingViewController
{
    CGRect frame = slidingViewController.view.bounds;
    CGFloat scaleFactor = self.scaleFactor;

    frame.origin.x    = slidingViewController.anchorRightRevealAmount;
    frame.size.width  = frame.size.width  * scaleFactor;
    frame.size.height = frame.size.height * scaleFactor;
    frame.origin.y    = (slidingViewController.view.bounds.size.height - frame.size.height) / 2;

    return frame;
}

- (void)configureTopView:(UIView*)view withState:(MITScaleAnimationState)state frame:(CGRect)frame
{
    switch (state) {
        case MITScaleAnimationStart: {
            view.layer.transform = CATransform3DIdentity;
            view.layer.position  = CGPointMake(CGRectGetMidX(frame),CGRectGetMidY(frame));
            view.layer.shadowOpacity = 0.0;
        } break;

        case MITScaleAnimationEnd: {
            view.layer.transform = CATransform3DMakeScale(self.scaleFactor, self.scaleFactor, 1);
            view.frame = frame;
            view.layer.position  = CGPointMake(frame.origin.x + ((view.layer.bounds.size.width * self.scaleFactor) / 2), view.layer.position.y);

            view.layer.shadowColor = [[UIColor blackColor] CGColor];
            view.layer.shadowRadius = 10.0;
            view.layer.shadowOpacity = 1.0;
            view.layer.shadowOffset = CGSizeZero;
        } break;
    }
}

- (void)configureLeftDrawerView:(UIView*)view withState:(MITScaleAnimationState)state frame:(CGRect)frame
{
    switch (state) {
        case MITScaleAnimationStart: {
            view.alpha = 0;
            view.frame = frame;
            view.layer.transform = CATransform3DMakeScale(1.25, 1.25, 1);
        } break;

        case MITScaleAnimationEnd: {
            view.alpha = 1;
            view.layer.transform = CATransform3DIdentity;
        } break;
    }
}

@end
