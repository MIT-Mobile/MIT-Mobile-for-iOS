#import "ToursModule.h"
#import "CampusTourHomeController.h"

@implementation ToursModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagTours title:@"Tours"];
    if (self) {
        self.longTitle = @"Campus Tour";
        self.imageName = @"tours";
    }

    return self;
}

- (void)loadRootViewController
{
    CampusTourHomeController *rootViewController = [[CampusTourHomeController alloc] init];
    self.rootViewController = rootViewController;
}

@end
