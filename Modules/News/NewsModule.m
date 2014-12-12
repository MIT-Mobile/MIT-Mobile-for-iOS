#import "NewsModule.h"

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
    UIStoryboard *storyboard = nil;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
   		storyboard = [UIStoryboard storyboardWithName:@"News_iPhone" bundle:nil];
	} else {
   		storyboard = [UIStoryboard storyboardWithName:@"News_iPad" bundle:nil];
	}
    NSAssert(storyboard, @"failed to load storyboard for %@",self);

    UIViewController *controller = [storyboard instantiateInitialViewController];
    self.viewController = controller;
}

@end
