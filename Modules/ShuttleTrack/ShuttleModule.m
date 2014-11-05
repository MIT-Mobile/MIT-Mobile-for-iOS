#import "ShuttleModule.h"
#import "MITShuttleHomeViewController.h"
#import "MITShuttleRootViewController.h"


@implementation ShuttleModule
- (instancetype)init {
    self = [super initWithName:MITModuleTagShuttle title:@"Shuttles"];
    if (self) {
        self.longTitle = @"ShuttleTrack";
        self.imageName = MITImageShuttlesModuleIcon;
    }
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIViewController *rootViewController = nil;
    UIUserInterfaceIdiom currentUserInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    if (UIUserInterfaceIdiomPhone == currentUserInterfaceIdiom) {
        rootViewController = [[MITShuttleHomeViewController alloc] init];
    } else if (UIUserInterfaceIdiomPad == currentUserInterfaceIdiom) {
        rootViewController = [[MITShuttleRootViewController alloc] init];
    }

    self.rootViewController = rootViewController;
}
	
@end
