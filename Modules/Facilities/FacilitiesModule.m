#import "FacilitiesModule.h"
#import "MITConstants.h"
#import "FacilitiesRootViewController.h"
#import "MITFacilitiesHomeViewController.h"

@interface FacilitiesModule()

@property (nonatomic, readonly) MITFacilitiesHomeViewController *facilitiesHomeVC;

@end

@implementation FacilitiesModule
- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = FacilitiesTag;
        self.shortName = @"Bldg Services";
        self.longName = @"Building Services";
        self.iconName = @"facilities";
    }
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController *)createHomeViewControllerForPhoneIdiom
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MITFacilities_iphone" bundle:nil];
    NSAssert(storyboard, @"failed to load storyboard for %@",self);
    
    _facilitiesHomeVC = [storyboard instantiateInitialViewController];
    
    return _facilitiesHomeVC;
}

/*
- (void)loadModuleHomeController
{
    self.moduleHomeController = [[FacilitiesRootViewController alloc] initWithNibName:@"FacilitiesRootViewController"
                                                                               bundle:nil];
}
*/

@end
