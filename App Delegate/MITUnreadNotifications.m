#import "MITUnreadNotifications.h"
#import "MITDeviceRegistration.h"
#import "MIT_MobileAppDelegate.h"
#import "MITModule.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

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
		
		[modulesBadgeString setObject:@(badgeCountInt) forKey:notification.moduleName];
	}
	

	// update the badge values for each tab item
	MIT_MobileAppDelegate *appDelegate = (MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate];
	for(MITModule *module in appDelegate.modules) {
		[module setBadgeValue:[modulesBadgeString[module.tag] stringValue]];
	}
	
	// update the total badge value for the application
	[UIApplication sharedApplication].applicationIconBadgeNumber = [notifications count];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UnreadBadgeValuesChangeNotification object:nil];
}
		

+ (MITTouchstoneRequestOperation *)requestOperationForCommand:(NSString *)command parameters:(NSDictionary *)params {
    NSURLRequest *request = [NSURLRequest requestForModule:@"push" command:command parameters:params];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSArray *notices) {
        NSAssert([notices isKindOfClass:[NSArray class]], @"expected an instance of NSArray, got %@", NSStringFromClass([notices class]));

        NSMutableArray *notifications = [NSMutableArray array];
        for(NSString *notice in notices) {
            [notifications addObject:[MITNotification fromString:notice]];
        }

        [MITUnreadNotifications saveUnreadNotifications:notifications];
        [MITUnreadNotifications updateUI];

        // since receiving the unread notices from the server is asynchrous event
        // we want all the modules to know that this data may have changed
        // so we pass of the new version of the data to each module
        NSArray *modules = ((MIT_MobileAppDelegate *)[[UIApplication sharedApplication] delegate]).modules;
        for (MITModule *module in modules) {
            NSMutableArray *moduleNotifications = [NSMutableArray array];

            for (MITNotification *notification in notifications) {
                if([notification.moduleName isEqualToString:module.tag]) {
                    [moduleNotifications addObject:notification];
                }
            }

            [module handleUnreadNotificationsSync:moduleNotifications];
        }

    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        DDLogWarn(@"request for v2:%@/%@ failed with error %@",@"push",command,[error localizedDescription]);
    }];

    return requestOperation;
}

// this method will get the most recent unread data from the MIT server
// and save it on the phone
+ (void) synchronizeWithMIT {
	MITIdentity *identity = [MITDeviceRegistration identity];
	
	if(identity) {
		NSMutableDictionary *parameters = [identity mutableDictionary];
        MITTouchstoneRequestOperation *request = [MITUnreadNotifications requestOperationForCommand:@"getUnreadNotifications" parameters:parameters];
        [[NSOperationQueue mainQueue] addOperation:request];
	}
}

// method calls MIT to tell it to remove the notification
// then syncs with the data MIT returns
+ (void)removeNotifications: (NSArray *)notifications {
	if([notifications count]) {
		MITIdentity *identity = [MITDeviceRegistration identity];
		
		if(identity) {
			NSMutableArray *noticeStrings = [NSMutableArray array];
			for(MITNotification *notification in notifications) {
				[noticeStrings addObject:[notification string]];
			}

			NSMutableDictionary *parameters = [identity mutableDictionary];

            NSData *noticeData = [NSJSONSerialization dataWithJSONObject:noticeStrings options:0 error:nil];
            parameters[@"tags"] = [[[NSString alloc] initWithData:noticeData encoding:NSUTF8StringEncoding] autorelease];

            MITTouchstoneRequestOperation *requestOperation = [MITUnreadNotifications requestOperationForCommand:@"markNotificationsAsRead" parameters:parameters];

            [[NSOperationQueue mainQueue] addOperation:requestOperation];
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
