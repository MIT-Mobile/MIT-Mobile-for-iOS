#import "ToursModule.h"
#import "MITModule.h"
#import "CampusTourHomeController.h"


@implementation ToursModule

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

- (void)loadModuleHomeController
{
    CampusTourHomeController *controller = [[CampusTourHomeController alloc] init];
    
    self.homeController = controller;
    self.moduleHomeController = controller;
}

@end
