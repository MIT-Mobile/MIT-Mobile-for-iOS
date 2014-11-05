#import "CMModule.h"

@implementation CMModule
- (instancetype)init
{
    self = [super initWithName:MITModuleTagCampusMap title:@"Map"];
    if (self != nil) {
        self.longTitle = @"Campus Map";
        self.imageName = MITImageMapModuleIcon;
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    MITMapHomeViewController *rootViewController = [[MITMapHomeViewController alloc] init];
    self.rootViewController = rootViewController;
}

@end
