#import <Foundation/Foundation.h>
#import "MITDeviceRegistration.h"

extern NSString* const MITNotificationModuleTagKey;

@interface MITNotification : NSObject <NSSecureCoding>
@property (nonatomic,readonly,copy) NSString *tag;
@property (nonatomic,readonly,copy) NSString *identifier;

+ (instancetype)notificationWithString:(NSString*)string;
- (instancetype)initWithModuleTag:(NSString*)tag noticeIdentifier:(NSString*)identifier;
- (NSString*)stringValue;
- (BOOL)isEqual:(id)object;
- (BOOL)isEqualToNotification:(MITNotification*)otherNotification;
@end

@interface MITNotification (Legacy)
@property (nonatomic,readonly) NSString *moduleName;
@property (nonatomic,readonly) NSString *noticeId;
+ (instancetype)fromString:(NSString*)noticeString;
- (NSString*)string;
- (BOOL)isEqualTo:(MITNotification*)other;
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

