#import "MITNavigationModule.h"

@implementation MITNavigationModule
@dynamic rootViewController;
@dynamic navigationController;

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

- (UINavigationController*)navigationController
{
    if ([self.viewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController*)self.navigationController;
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"view controller must be kind of UINavigationController"
                                     userInfo:nil];
    }
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    NSParameterAssert(rootViewController);
    [self.navigationController setViewControllers:@[rootViewController]];
}

- (UIViewController*)rootViewController
{
    return [self.navigationController.viewControllers firstObject];
}

@end
