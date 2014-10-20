#import "NewsModule.h"

#import "MITNewsViewController.h"

@implementation NewsModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagNewsOffice title:@"News"];
    if (self) {
        self.longTitle = @"News Office";
        self.imageName = @"news";
    }
    
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"News" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);

    UIViewController *controller = [storyboard instantiateInitialViewController];

    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)controller;
        self.viewController = controller;
        self.rootViewController = navigationController.viewControllers[0];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"view controller must be a kind of UINavigationController" userInfo:nil];
    }
}

@end
