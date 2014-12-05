#import "ToursModule.h"
#import "MITModule.h"
#import "MITToursHomeViewController.h"
#import "MITToursHomeViewControllerPad.h"

@implementation ToursModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagTours title:@"Tours"];
    if (self) {
        self.longTitle = @"Campus Tour";
        self.imageName = MITImageToursModuleIcon;
    }

    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIViewController *rootViewController = nil;
    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    
    if (UIUserInterfaceIdiomPad == userInterfaceIdiom) {
        rootViewController = [[MITToursHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
    } else if (UIUserInterfaceIdiomPhone == userInterfaceIdiom) {
        rootViewController = [[MITToursHomeViewController alloc] initWithNibName:nil bundle:nil];
    }
    
    self.rootViewController = rootViewController;
}

@end
