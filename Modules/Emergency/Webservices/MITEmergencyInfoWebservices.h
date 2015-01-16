#import <Foundation/Foundation.h>
#import "MITEmergencyInfoAnnouncement.h"

@interface MITEmergencyInfoWebservices : NSObject

+ (void)getEmergencyContacts:(void (^)(NSArray *contacts, NSError *error))completion;
+ (void)getEmergencyAnnouncement:(void (^)(MITEmergencyInfoAnnouncement *announcement, NSError *error))completion;

@end
