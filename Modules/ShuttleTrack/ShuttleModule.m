#import "ShuttleModule.h"
#import "ShuttleRoutes.h"
#import "ShuttleSubscriptionManager.h"

@implementation ShuttleModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = ShuttleTag;
        self.shortName = @"Shuttles";
        self.longName = @"ShuttleTrack";
        self.iconName = @"shuttle";
        self.pushNotificationSupported = YES;

        ShuttleRoutes *theVC = [[[ShuttleRoutes alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:theVC]];
    }
    return self;
}

- (void) didAppear {
	// for now mark all shuttle notifications as read as soon as the module appears to the user
	[MITUnreadNotifications removeNotifications:[MITUnreadNotifications unreadNotificationsForModuleTag:self.tag]];
}


- (void) removeSubscriptionByNotification: (MITNotification *)notification {
	NSArray *parts = [notification.noticeId componentsSeparatedByString: @":"];
	NSString *routeId = [parts objectAtIndex:0];
	NSString *stopId = [parts objectAtIndex:1];
	[ShuttleSubscriptionManager removeSubscriptionForRouteId:routeId atStopId:stopId];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ShuttleAlertRemoved object:notification];
}
	
- (BOOL) handleNotification:(MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen {
	// for now just open the module in response to a notification
	[self removeSubscriptionByNotification:notification];
	
	if([self isActiveTab]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
	
	if(shouldOpen) {
		[appDelegate showModuleForTag:self.tag];
	}
	return YES;
}

- (void) handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
	for(MITNotification *aNotification in unreadNotifications) {
		[self removeSubscriptionByNotification:aNotification];
	}
	
	if([self isActiveTab]) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
}

@end
