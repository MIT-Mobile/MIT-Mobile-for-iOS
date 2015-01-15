#import "MITEmergencyInfoWebservices.h"
#import "MITMobileRouteConstants.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"

@implementation MITEmergencyInfoWebservices

+ (void)getEmergencyContacts:(void (^)(NSArray *contacts, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITEmergencyInfoContactsResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    completion(result.array, error);
                                                }];
}

+ (void)getEmergencyAnnouncements:(void (^)(NSArray *announcements, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITEmergencyInfoAnnouncementResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    completion(result.array, error);
                                                }];
}

@end
