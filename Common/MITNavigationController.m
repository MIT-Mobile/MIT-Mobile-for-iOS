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
    if ([self visibleViewController]) {
        return [[self visibleViewController] preferredInterfaceOrientationForPresentation];
    } else {
        return [super preferredInterfaceOrientationForPresentation];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self visibleViewController]) {
        return [[self visibleViewController] supportedInterfaceOrientations];
    } else {
        return [super supportedInterfaceOrientations];
    }
}

- (BOOL)shouldAutorotate
{
    if ([self visibleViewController]) {
        return [[self visibleViewController] shouldAutorotate];
    } else {
        return [self shouldAutorotate];
    }
}

@end
