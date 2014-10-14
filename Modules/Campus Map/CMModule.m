#import "CMModule.h"

@implementation CMModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagCampusMap title:@"Map"];
    if (self != nil) {
        self.longTitle = @"Campus Map";
        self.imageName = @"icons/home-map";
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    MITCampusMapViewController *rootViewController = [[MITCampusMapViewController alloc] init];
    self.rootViewController = rootViewController;
}

@end
