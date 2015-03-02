#import "MITSlidingUnderLeftSegue.h"
#import <ECSlidingViewController/ECSlidingViewController.h>

@implementation MITSlidingUnderLeftSegue

- (void)perform {
    UIViewController *fromViewController = self.sourceViewController;
    UIViewController *underLeftViewController = self.destinationViewController;
    
    if ([fromViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *slidingViewController = (ECSlidingViewController*)self.sourceViewController;
        [slidingViewController setUnderLeftViewController:underLeftViewController];
    }
}

@end
