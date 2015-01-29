#import "MITNavigationController.h"

@interface MITNavigationController ()

@end

@implementation MITNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if ([self topViewController]) {
        return [[self topViewController] preferredInterfaceOrientationForPresentation];
    } else {
        return [super preferredInterfaceOrientationForPresentation];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self topViewController]) {
        return [[self topViewController] supportedInterfaceOrientations];
    } else {
        return [super supportedInterfaceOrientations];
    }
}

- (BOOL)shouldAutorotate
{
    if ([self topViewController]) {
        return [[self topViewController] shouldAutorotate];
    } else {
        return [self shouldAutorotate];
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}

@end
