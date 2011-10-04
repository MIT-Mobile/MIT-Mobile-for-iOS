
#import "MITUnreadNotifications.h"
#import "MITDeviceRegistration.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "SBJSON.h"

#define TAB_COUNT 4


@implementation MITUnreadNotifications

// save the unread notifications to disk, it overwrites the previous notifications
+ (void) saveUnreadNotifications: (NSArray *)notifications {
	NSMutableArray *arrayToSave = [NSMutableArray arrayWithCapacity:[notifications count]];
	for(MITNotification *notification in notifications) {
		[arrayToSave addObject:[notification string]];
	}
	[[NSUserDefaults standardUserDefaults] setObject:arrayToSave forKey:MITUnreadNotificationsKey];
}
	
+ (NSArray *) unreadNotifications {
	NSMutableArray *notifications = [NSMutableArray array];
	NSArray *savedData = [[NSUserDefaults standardUserDefaults] arrayForKey:MITUnreadNotificationsKey];
	
	for(NSString *noticeString in savedData) {		
		[notifications addObject:[MITNotification fromString:noticeString]];
	}
	return notifications;
}

+ (NSArray *) unreadNotificationsForModuleTag: (NSString *)moduleTag {
	NSMutableArray *notifications = [NSMutableArray array];
	for(MITNotification *notification in [self unreadNotifications]) {
		if([notification.moduleName isEqualToString:moduleTag]) {
			[notifications addObject:notification];
		}
	}
	return notifications;
}

// this method will update the badge numbers in the tab bar
+ (void) updateUI {
	int badgeCountInt = 0;
	
	NSMutableDictionary *modulesBadgeString = [NSMutableDictionary dictionary];
	NSArray *notifications = [MITUnreadNotifications unreadNotifications];
	for(MITNotification *notification in notifications) {
        NSNumber *badgeCount = [modulesBadgeString objectForKey:notification.moduleName];
		if(badgeCount) {
			badgeCountInt = [badgeCount intValue] + 1;
		} else {
			badgeCountInt = 1;
		}
		
		[modulesBadgeString setObject:[NSNumber numberWithInt:badgeCountInt] forKey:notification.moduleName];
	}
	

	// update the badge values for each tab item
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	for(MITModule *module in appDelegate.modules) {
		NSNumber *badgeValue = [modulesBadgeString objectForKey:module.tag];
		NSString *badgeString = nil;
		if (badgeValue) {
			badgeString = [badgeValue stringValue];
		}
		[module setBadgeValue:badgeString];
	}
	
	// update the total badge value for the application
	[UIApplication sharedApplication].applicationIconBadgeNumber = [notifications count];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UnreadBadgeValuesChangeNotification object:nil];
}
		



// this method will get the most recent unread data from the MIT server
// and save it on the phone
+ (void) synchronizeWithMIT {
	MITIdentity *identity = [MITDeviceRegistration identity];
	
	if(identity) {
		NSMutableDictionary *parameters = [identity mutableDictionary];
		[[MITMobileWebAPI jsonLoadedDelegate:[[SynchronizeUnreadNotificationsDelegate new] autorelease]]
			requestObjectFromModule:@"push" command:@"getUnreadNotifications" parameters:parameters];
	}
}

// method calls MIT to tell it to remove the notification
// then syncs with the data MIT returns
+ (void) removeNotifications: (NSArray *)notifications {
	if([notifications count]) {
		MITIdentity *identity = [MITDeviceRegistration identity];
		
		if(identity) {
			NSMutableArray *noticeStrings = [NSMutableArray array];
			for(MITNotification *notification in notifications) {
				[noticeStrings addObject:[notification string]];
			}		
			SBJSON *sbjson = [SBJSON new];
		
			NSMutableDictionary *parameters = [identity mutableDictionary];
			[parameters setObject:[sbjson stringWithObject:noticeStrings] forKey:@"tags"];
		
			[[MITMobileWebAPI jsonLoadedDelegate:[[SynchronizeUnreadNotificationsDelegate new] autorelease]]
				requestObjectFromModule:@"push" command:@"markNotificationsAsRead" parameters:parameters];
		
			[sbjson release];
		}
        
        [MITUnreadNotifications updateUI];
	}
}

+ (void) removeNotificationsForModuleTag: (NSString *)moduleTag {
	[self removeNotifications:[self unreadNotificationsForModuleTag:moduleTag]];
}

// method adds a notification to the phone (from an APNS dictionary)
+ (MITNotification *) addNotification: (NSDictionary *)apnsDictionary {
	MITNotification *notification = [MITNotification fromString:[apnsDictionary objectForKey:@"tag"]];
	
	if(![apnsDictionary objectForKey:@"noBadge"]) {
		if(![self hasUnreadNotification:notification]) {
			NSMutableArray *notifications = [NSMutableArray arrayWithArray:[self unreadNotifications]];
			[notifications addObject:notification];
			[self saveUnreadNotifications:notifications];
			[self updateUI];
		}
	}
	return notification;
}

// checks if a certain type of notification exists (and is unread)
+ (BOOL) hasUnreadNotification: (MITNotification *)possibleNotification {
	for(MITNotification *notification in [self unreadNotifications]) {
		if([notification isEqualTo:possibleNotification]) {
			return YES;
		}
	}
	return NO;
}

@end

@implementation MITNotification
@synthesize moduleName, noticeId;

+ (MITNotification *) fromString: (NSString *)noticeString {
	// a colon is used to seperate the moduleName from the notification id
	NSRange colonRange = [noticeString rangeOfString:@":"];
	
	return [[[self alloc] 
		initWithModuleName:[noticeString substringToIndex:colonRange.location] 
		noticeId:[noticeString substringFromIndex:(colonRange.location+1)]]
			autorelease];
}
	
- (id) initWithModuleName: (NSString *)aModuleName noticeId: (NSString *)anId {
	self = [super init];
	if (self) {
		moduleName = [aModuleName retain];
		noticeId = [anId retain];
	}
	return self;
}
	
- (NSString *) string {
	return [NSString stringWithFormat:@"%@:%@", moduleName, noticeId];
}

- (BOOL) isEqualTo: (MITNotification *)other {
	return [[self string] isEqualToString:[other string]];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"{module:%@, tag:%@}", moduleName, noticeId];
}
@end

@implementation SynchronizeUnreadNotificationsDelegate 

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)JSONObject {
	if (JSONObject && [JSONObject isKindOfClass:[NSArray class]]) {
		NSMutableArray *notifications = [NSMutableArray array];
		for(NSString *noticeString in (NSArray *)JSONObject) {
			[notifications addObject:[MITNotification fromString:noticeString]];
		}
		
		[MITUnreadNotifications saveUnreadNotifications:notifications];
		[MITUnreadNotifications updateUI];
		
		// since receiving the unread notices from the server is asynchrous event
		// we want all the modules to know that this data may have changed
		// so we pass of the new version of the data to each module
		NSArray *modules = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
		for(MITModule *module in modules) {
			NSMutableArray *moduleNotifications = [NSMutableArray array];
			
			for(MITNotification *notification in notifications) {
				if([notification.moduleName isEqualToString:module.tag]) {
					[moduleNotifications addObject:notification];
				}
			}
			[module handleUnreadNotificationsSync:moduleNotifications];
		}
	}
}

- (BOOL) request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError:(NSError *)error {
	return NO;
}

@end

