#import "ShuttleModule.h"
#import "ShuttleRoute.h"
#import "ShuttleRoutes.h"
#import "ShuttleRouteViewController.h"
#import "ShuttleSubscriptionManager.h"
#import "ShuttleStopMapAnnotation.h"

#import "MITModule+Protected.h"

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
    [self setModuleHomeController:[[ShuttleRoutes alloc] initWithStyle:UITableViewStyleGrouped]];
}

- (void) didAppear {
	// for now mark all shuttle notifications as read as soon as the module appears to the user
	[MITUnreadNotifications removeNotifications:[MITUnreadNotifications unreadNotificationsForModuleTag:self.tag]];
}


- (void) removeSubscriptionByNotification: (MITNotification *)notification {
	NSArray *parts = [notification.noticeId componentsSeparatedByString: @":"];
	NSString *routeID = parts[0];
	NSString *stopID = parts[1];
	[ShuttleSubscriptionManager removeSubscriptionForRouteID:routeID atStopID:stopID];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ShuttleAlertRemoved object:notification];
}
	
- (BOOL)handleNotification:(MITNotification *)notification shouldOpen: (BOOL)shouldOpen {
	// for now just open the module in response to a notification
	[self removeSubscriptionByNotification:notification];
	
	if(shouldOpen) {
		NSString *routeID = [notification.noticeId componentsSeparatedByString:@":"][0];
		[self handleLocalPath:[NSString stringWithFormat:@"route-list/%@", routeID] query:nil];
	}
	
	return YES;
}

- (void) handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
	for(MITNotification *aNotification in unreadNotifications) {
		[self removeSubscriptionByNotification:aNotification];
	}
	
	if([[MITAppDelegate() rootNavigationController] visibleViewController] == self.moduleHomeController) {
		[MITUnreadNotifications removeNotificationsForModuleTag:self.tag];
	}
}

- (BOOL) handleLocalPath:(NSString *)localPath query:(NSString *)query {
    [[MIT_MobileAppDelegate applicationDelegate] showModuleForTag:self.tag];
    
    if ([localPath length] == 0) {
		return YES;
	}
	
	NSArray *components = [localPath pathComponents];
	NSString *pathRoot = components[0];
	UINavigationController *navigationController = [self rootViewController].navigationController;
	 
	if ([pathRoot isEqualToString:@"route-list"] || [pathRoot isEqualToString:@"route-map"]) {
		NSString *routeID = components[1];
		ShuttleRoute *route = [ShuttleDataManager shuttleRouteWithID:routeID];
		if(route) {
			ShuttleRouteViewController *routeViewController = [[ShuttleRouteViewController alloc] initWithNibName:@"ShuttleRouteViewController" bundle:nil];
			routeViewController.route = route;
			[navigationController pushViewController:routeViewController
                                            animated:NO];
			
			ShuttleStop *stop = nil;
			ShuttleStopMapAnnotation *annotation = nil;
			if ([components count] > 2) {
				NSString *stopID = components[2];
                NSError *error = nil;
				stop = [ShuttleDataManager stopWithRoute:routeID stopID:stopID error:&error];
				
				// need to force routeViewController to load to initialize the route annotations
				(void)routeViewController.view;
				for (ShuttleStopMapAnnotation *anAnnotation in [routeViewController.route annotations]) {
					if ([anAnnotation.shuttleStop.stopID isEqualToString:stopID]) {
						annotation = anAnnotation;
					}
				}
			}
			
			if ([pathRoot isEqualToString:@"route-list"]) {
				if (stop) {
					[routeViewController pushStopViewControllerWithStop:stop
                                                             annotation:annotation
                                                               animated:NO];
				}
			}
			
			// for route map case
			if([pathRoot isEqualToString:@"route-map"]) {
				[routeViewController setMapViewMode:YES
                                           animated:NO];
				if (stop) {
					// show a specific stop
					[routeViewController showStop:annotation
                                         animated:NO];
				}
				
				if ([components count] > 3 && 
					[@"stops" isEqualToString:components[3]]) {
						[routeViewController pushStopViewControllerWithStop:stop
                                                                 annotation:annotation
                                                                   animated:NO];
				}
			}
		}
	}
	return YES;
}
	
@end
