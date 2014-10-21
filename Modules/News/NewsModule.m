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
    self.viewController = controller;
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController*)controller;
        self.rootViewController = navigationController.viewControllers[0];
    }
}

@end
