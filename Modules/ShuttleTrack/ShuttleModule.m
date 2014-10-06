#import "ShuttleModule.h"
#import "MITShuttleHomeViewController.h"
#import "MITShuttleRootViewController.h"


@implementation ShuttleModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = ShuttleTag;
        self.shortName = @"Shuttles";
        self.longName = @"ShuttleTrack";
        self.iconName = @"shuttle";
        self.pushNotificationSupported = YES;
    }
    return self;
}

- (BOOL)supportsUserInterfaceIdiom:(UIUserInterfaceIdiom)idiom
{
    return YES;
}

- (UIViewController*)createHomeViewControllerForPadIdiom
{
    return [[MITShuttleRootViewController alloc] initWithNibName:nil bundle:nil];
}

- (UIViewController*)createHomeViewControllerForPhoneIdiom
{
    return [[MITShuttleHomeViewController alloc] initWithNibName:nil bundle:nil];
}
	
@end
