#import "StellarModule.h"
#import "StellarMainTableController.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "StellarModel.h"
#import "StellarAnnouncementViewController.h"
#import "StellarDetailViewController.h"
#import "StellarClassesTableController.h"
#import "StellarCoursesTableController.h"
#import "MITConstants.h"

#import "MITModule+Protected.h"

@implementation StellarModule

- (id)init
{
	self = [super init];
    if (self != nil) {
        self.tag = StellarTag;
        self.shortName = @"Stellar";
        self.longName = @"MIT Stellar";
        self.iconName = @"stellar";
        self.pushNotificationSupported = YES;
    }
    return self;
}

- (void)loadModuleHomeController
{
    [self setModuleHomeController:[[[StellarMainTableController alloc] init] autorelease]];
}


- (BOOL)handleNotification:(MITNotification *)notification shouldOpen: (BOOL)shouldOpen {
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarAlertNotification object:nil];
	
	if(shouldOpen) {		
		// mark Launch as begun so we dont handle the path twice.
		hasLaunchedBegun = YES;
		[self handleLocalPath:[NSString stringWithFormat:@"class/%@/News", notification.noticeId] query:nil];

	}
	return YES;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
	// which classes have unread messages may have changed, so broadcast that my stellar may have changed
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarAlertNotification object:nil];

	NSArray *stellarClasses = [StellarModel myStellarClasses];
	NSMutableArray *unusedNotifications = [NSMutableArray array];
	
	// check if any of the unread messages are no longer in "myStellar" list
	for(MITNotification *notification in unreadNotifications) {
		BOOL found = NO;
		for(StellarClass *class in stellarClasses) {
			if([class.masterSubjectId isEqualToString:notification.noticeId]) {
				found = YES;
			}
		}
		
		if(!found) {
			// class not in myStellar, so will probably never get read, just clear it from the unread list now
			[unusedNotifications addObject:notification];
		}
	}
	[MITUnreadNotifications removeNotifications:unusedNotifications];
}

- (BOOL)handleLocalPath:(NSString *)localPath query:(NSString *)query {
//	NSArray *pathComponents = [localPath componentsSeparatedByString:@"/"];
//	NSString *pathRoot = [pathComponents objectAtIndex:0];
    
    if ([[[MITAppDelegate() rootNavigationController] viewControllers] containsObject:self.moduleHomeController]) {
        [[MITAppDelegate() rootNavigationController] popToViewController:self.moduleHomeController animated:NO];
    } else {
        [[MITAppDelegate() rootNavigationController] popToRootViewControllerAnimated:NO];
        [[MITAppDelegate() springboardController] pushModuleWithTag:self.tag];
    }
/*    
	if ([pathRoot isEqualToString:@"class"]) {
		StellarClass *stellarClass = [StellarModel classWithMasterId:[pathComponents objectAtIndex:1]];
		if(stellarClass) {
			StellarDetailViewController *detailViewController = [StellarDetailViewController launchClass:stellarClass viewController:self.moduleHomeController];
			if ([pathComponents count] > 2) {
				[detailViewController setCurrentTab:[pathComponents objectAtIndex:2]];
			}
			// check to see if we drilling down into a news announcment
			if (([pathComponents count] > 3) && [[pathComponents objectAtIndex:2] isEqualToString:@"News"]) {
				NSInteger announcementIndex = [[pathComponents objectAtIndex:3] integerValue];
				NSArray *announcements = [StellarModel sortedAnnouncements:stellarClass];
				if (announcements.count > announcementIndex) {
					StellarAnnouncement *announcement = [announcements objectAtIndex:announcementIndex];
					detailViewController.refreshClass = NO;
					StellarAnnouncementViewController *announcementViewController = [[StellarAnnouncementViewController alloc] 
						initWithAnnouncement:announcement rowIndex:announcementIndex];
					[detailViewController.navigationController pushViewController:announcementViewController animated:NO];
					[announcementViewController release];
				}
			}
		}
		
	} else if ([pathRoot isEqualToString:@"courses"]) {
		NSString *courseGroupString = [pathComponents objectAtIndex:1];
		StellarCourseGroup *courseGroup = [StellarCourseGroup deserialize:courseGroupString];
		
		if(courseGroup) {
			StellarCoursesTableController *coursesTableController = [[StellarCoursesTableController alloc] initWithCourseGroup:courseGroup];
			[self.moduleHomeController.navigationController pushViewController:coursesTableController animated:NO]; 			 
			
			if ([pathComponents count] > 2) {
				NSString *courseId = [pathComponents objectAtIndex:2];
				StellarCourse *course = [StellarModel courseWithId:courseId];
				
				if (course) {
					StellarClassesTableController *classesTableController = [[StellarClassesTableController alloc] initWithCourse:course];
					[coursesTableController.navigationController pushViewController:classesTableController animated:NO];
					[classesTableController release];
				}
			}
			
			[coursesTableController release];
		}
		
	} else if ([pathRoot isEqualToString:@"search-begin"] || [pathRoot isEqualToString:@"search-complete"]) {
		// need to force the view to load before activating the doSearch method
		(void)self.moduleHomeController.view;
		[(StellarMainTableController *)self.moduleHomeController doSearch:query execute:[pathRoot isEqualToString:@"search-complete"]];
	}
*/
	return YES;
}

- (void)dealloc
{
	[super dealloc];
}

@end
