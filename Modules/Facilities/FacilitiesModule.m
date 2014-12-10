#import "FacilitiesModule.h"
#import "MITConstants.h"
#import "FacilitiesRootViewController.h"
#import "MITFacilitiesHomeViewController.h"

@implementation FacilitiesModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagFacilities title:@"Bldg Services"];
    if (self) {
        self.longTitle = @"Building Services";
        self.imageName = MITImageBuildingServicesModuleIcon;
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
   		storyboard = [UIStoryboard storyboardWithName:@"MITFacilities_iphone" bundle:nil];
	} else {
   		storyboard = [UIStoryboard storyboardWithName:@"MITFacilities_ipad" bundle:nil];
	}
    NSAssert(storyboard, @"failed to load storyboard for %@",self);

    UIViewController *controller = [storyboard instantiateInitialViewController];
    self.viewController = controller;
}

@end
