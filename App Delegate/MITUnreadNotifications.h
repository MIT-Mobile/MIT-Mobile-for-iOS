
#import <Foundation/Foundation.h>
#import "MITMobileWebAPI.h"
#import "MIT_MobileAppDelegate+ModuleList.h"
#import "MITDeviceRegistration.h"

@interface MITNotification : NSObject
{
	NSString *moduleName;
	NSString *noticeId;
}

@property (readonly) NSString *moduleName;
@property (readonly) NSString *noticeId;

+ (MITNotification *) fromString: (NSString *)noticeString;

- (id) initWithModuleName: (NSString *)moduleName noticeId: (NSString *)noticeId;

- (NSString *) string;

- (BOOL) isEqualTo: (MITNotification *)other;
@end

@interface MITUnreadNotifications : NSObject {

}

// returns the unreadNotifications stored on the phone
+ (NSArray *) unreadNotifications;

// returns the unreadNotifications for a specific module
+ (NSArray *) unreadNotificationsForModuleTag: (NSString *)moduleTag;

// this method will update the badge numbers in the tab bar
+ (void) updateUI;

// this method will get the most recent unread data from the MIT server
// and save it on the phone
+ (void) synchronizeWithMIT;

// method calls MIT to tell it to remove the notification
// then syncs with the data MIT returns
+ (void) removeNotifications: (NSArray *)notifications;

// a convenience method to remove all modules
+ (void) removeNotificationsForModuleTag: (NSString *)moduleTag;

// method adds a notification to the phone (from an APNS dictionary)
// then calls MIT to be sure it is synced properly
+ (MITNotification *) addNotification: (NSDictionary *)apnsDictionary;

// checks if a certain type of notification exists (and is unread)
+ (BOOL) hasUnreadNotification: (MITNotification *)notification;

@end


@interface SynchronizeUnreadNotificationsDelegate : NSObject <JSONLoadedDelegate> { }

@end
