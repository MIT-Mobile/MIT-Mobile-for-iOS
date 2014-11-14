#import "NewsModule.h"

#import "MITNewsViewController.h"

@implementation NewsModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagNewsOffice title:@"News"];
    if (self) {
        self.longTitle = @"News Office";
        self.imageName = MITImageNewsModuleIcon;
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
}

@end
