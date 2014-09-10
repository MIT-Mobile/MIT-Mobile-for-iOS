#import <Foundation/Foundation.h>
#import "ECSlidingViewController.h"

@interface MITScaleAnimationController : NSObject <UIViewControllerAnimatedTransitioning, ECSlidingViewControllerLayout>
@property(nonatomic,readonly) ECSlidingViewControllerOperation operation;
@property(nonatomic,readonly) CGFloat scaleFactor;

- (instancetype)initWithOperation:(ECSlidingViewControllerOperation)operation scaleFactor:(CGFloat)scaleFactor;

@end
