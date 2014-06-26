#import "ShuttleModule.h"
#import "MITShuttleHomeViewController.h"



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

- (void)loadModuleHomeController
{
    [self setModuleHomeController:[[MITShuttleHomeViewController alloc] initWithNibName:nil bundle:nil]];
//    [self setModuleHomeController:[[ShuttleRoutes alloc] initWithStyle:UITableViewStyleGrouped]];
}

- (void) didAppear {
	// for now mark all shuttle notifications as read as soon as the module appears to the user
	[MITUnreadNotifications removeNotifications:[MITUnreadNotifications unreadNotificationsForModuleTag:self.tag]];
}

@end
