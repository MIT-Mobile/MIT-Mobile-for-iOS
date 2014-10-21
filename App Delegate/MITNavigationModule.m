#import "MITNavigationModule.h"

@implementation MITNavigationModule {
    __weak UIViewController *_rootViewController;
}

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

- (UINavigationController*)navigationController
{
    if ([self.viewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController*)self.viewController;
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"view controller must be kind of UINavigationController"
                                     userInfo:nil];
    }
}

- (void)loadViewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    self.viewController = navigationController;
}

- (void)setViewController:(UIViewController *)viewController
{
    if (![viewController isKindOfClass:[UINavigationController class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"view controller must be a kind of UINavigationController" userInfo:nil];
    } else {
        [super setViewController:viewController];
    }
}

- (void)viewControllerDidLoad
{
    [super viewControllerDidLoad];

    if (![self isRootViewControllerLoaded]) {
        [self loadRootViewController];
    }
}

- (BOOL)isRootViewControllerLoaded
{
    return (_rootViewController != nil);
}

- (void)loadRootViewController
{
    if ([self.navigationController.viewControllers count]) {
        _rootViewController = [self.navigationController.viewControllers firstObject];
    } else {
        UIView *view = [[UIView alloc] init];
        view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
        view.backgroundColor = [UIColor whiteColor];
    
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view = view;
    
        self.rootViewController = viewController;
    }
}

- (void)setRootViewController:(UIViewController *)rootViewController
{
    NSParameterAssert(rootViewController);

    if (_rootViewController != rootViewController) {
        _rootViewController = rootViewController;
        [self.navigationController setViewControllers:@[rootViewController]];
    }
}

- (UIViewController*)rootViewController
{
    if (![self isRootViewControllerLoaded]) {
        [self loadRootViewController];
    }

    return _rootViewController;
}

@end
