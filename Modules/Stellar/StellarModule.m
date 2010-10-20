#import "StellarModule.h"
#import "StellarMainTableController.h"
#import "MITModuleList.h"
#import "StellarModel.h"
#import "StellarDetailViewController.h"

@implementation StellarModule

@synthesize navigationController;

- (id)init
{
	self = [super init];
    if (self != nil) {
        self.tag = StellarTag;
        self.shortName = @"Stellar";
        self.longName = @"MIT Stellar";
        self.iconName = @"stellar";
        self.pushNotificationSupported = YES;
		
		StellarMainTableController *stellarMainTableController = [[[StellarMainTableController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		stellarMainTableController.navigationItem.title = @"MIT Stellar";
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:stellarMainTableController]];
    }
    return self;
}


- (BOOL)handleNotification:(MITNotification *)notification appDelegate: (MIT_MobileAppDelegate *)appDelegate shouldOpen: (BOOL)shouldOpen {
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
	
	if(shouldOpen) {
		[appDelegate showModuleForTag:self.tag];
		[self.tabNavController popToRootViewControllerAnimated:NO];
		StellarClass *stellarClass = [StellarModel emptyClassWithMasterId:notification.noticeId];
		[StellarDetailViewController launchClass:stellarClass viewController:self.tabNavController.topViewController];
	}
	return YES;
}

- (void)handleUnreadNotificationsSync: (NSArray *)unreadNotifications {
	// which classes have unread messages may have changed, so broadcast that my stellar may have changed
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];

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

- (void)dealloc
{
	[super dealloc];
}



@end
