#import <Foundation/Foundation.h>

@interface MITEmergencyInfoWebservices : NSObject

+ (void)getEmergencyContacts:(void (^)(NSArray *contacts, NSError *error))completion;
+ (void)getEmergencyAnnouncement:(void (^)(NSArray *announcement, NSError *error))completion;

@end
