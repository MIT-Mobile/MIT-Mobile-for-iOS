#import "ToursModule.h"
#import "MITModule.h"
#import "CampusTourHomeController.h"

@implementation ToursModule

@synthesize homeController;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = ToursTag;
        self.shortName = @"Tours";
        self.longName = @"Campus Tour";
        self.iconName = @"tours";
    }
    return self;
}

- (UIViewController *)moduleHomeController {
    if (!self.homeController) {
        self.homeController = [[[CampusTourHomeController alloc] init] autorelease];
    }
    return self.homeController;
}

- (void)applicationWillEnterBackground {
}

@end
