#import "MITNavigationModule.h"

@implementation MITNavigationModule
- (instancetype)initWithName:(NSString *)name title:(NSString *)title
{
    self = [super initWithName:name title:title];
    if (self) {
        // Do Nothing
    }
    
    return self;
}

- (void)loadViewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    self.viewController = navigationController;
    
    [self loadRootViewController];
}

- (void)loadRootViewController
{
    UIView *view = [[UIView alloc] init];
    view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    view.backgroundColor = [UIColor whiteColor];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = view;
    
    self.rootViewController = viewController;
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    NSParameterAssert(rootViewController);
    
    if (_rootViewController != rootViewController) {
        [_navigationController setViewControllers:@[rootViewController]];
        _rootViewController = rootViewController;
    }
}

@end
