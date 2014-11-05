#import "FacilitiesModule.h"
#import "MITConstants.h"
#import "FacilitiesRootViewController.h"

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

- (void)loadRootViewController
{
    FacilitiesRootViewController *rootViewController = [[FacilitiesRootViewController alloc] initWithNibName:@"FacilitiesRootViewController" bundle:nil];
    
    self.rootViewController = rootViewController;
}

@end
