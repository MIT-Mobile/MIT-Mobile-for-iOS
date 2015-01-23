#import "MITMartyModule.h"

@implementation MITMartyModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagMarty title:@"Marty"];
    if (self) {
        self.longTitle = @"Marty";
        self.imageName = MITImageMartyModuleIcon;
    }
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MartyStoryboard" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    UIViewController *controller = [storyboard instantiateInitialViewController];
    self.viewController = controller;
}
	
@end
