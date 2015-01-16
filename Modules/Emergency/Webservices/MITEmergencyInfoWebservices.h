#import <Foundation/Foundation.h>

@class MITEmergencyInfoAnnouncement;

@interface MITEmergencyInfoWebservices : NSObject

+ (void)getEmergencyContacts:(void (^)(NSArray *contacts, NSError *error))completion;
+ (void)getEmergencyAnnouncement:(void (^)(MITEmergencyInfoAnnouncement *announcement, NSError *error))completion;

@end
