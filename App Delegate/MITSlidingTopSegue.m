#import "MITSlidingTopSegue.h"
#import "ECSlidingViewController.h"

@implementation MITSlidingTopSegue

- (void)perform {
    UIViewController *fromViewController = self.sourceViewController;
    UIViewController *topViewController = self.destinationViewController;
    
    if ([fromViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *slidingViewController = (ECSlidingViewController*)fromViewController;
        [slidingViewController setTopViewController:topViewController];
    }
}

@end
