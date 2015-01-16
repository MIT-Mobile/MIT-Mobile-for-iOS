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

+ (void)getEmergencyAnnouncement:(void (^)(MITEmergencyInfoAnnouncement *announcement, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITEmergencyInfoAnnouncementResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    
                                                    MITEmergencyInfoAnnouncement *announcement = nil;
                                                    
                                                    if ([result.array count]) {
                                                        id obj = result.array[0];
                                                    
                                                        if ([obj isKindOfClass:[MITEmergencyInfoAnnouncement class]]) {
                                                            announcement = (MITEmergencyInfoAnnouncement *)result.array[0];
                                                        }
                                                    }
                                                    completion(announcement, error);
                                                }];
}

@end
