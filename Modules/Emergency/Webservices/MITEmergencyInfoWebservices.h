#import <Foundation/Foundation.h>

@interface MITEmergencyInfoWebservices : NSObject

+ (void)getEmergencyContacts:(void (^)(NSArray *contacts, NSError *error))completion;
+ (void)getEmergencyAnnouncements:(void (^)(NSDictionary *announcements, NSError *error))completion;

@end
