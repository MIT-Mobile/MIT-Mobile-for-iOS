#import "ToursModule.h"
#import "CampusTourHomeController.h"
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

//- (void)loadModuleHomeController
//{
//    CampusTourHomeController *controller = [[CampusTourHomeController alloc] init];
//    
//    self.homeController = controller;
//    self.moduleHomeController = controller;
//}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITToursHomeViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITToursHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
}

@end
