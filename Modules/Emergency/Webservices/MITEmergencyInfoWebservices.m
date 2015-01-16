#import "MITEmergencyInfoWebservices.h"
#import "MITMobileRouteConstants.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITEmergencyInfoAnnouncement.h"

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
    NSParameterAssert(completion);
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITEmergencyInfoAnnouncementResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        MITEmergencyInfoAnnouncement *announcement = [result.array firstObject];
                                                        
                                                        if ([announcement isKindOfClass:[MITEmergencyInfoAnnouncement class]]) {
                                                            completion(announcement, nil);
                                                        } else if (announcement) {
                                                            NSString *message = [NSString stringWithFormat:@"emergency announcement is kind of %@, expected %@",NSStringFromClass([announcement class]), NSStringFromClass([MITEmergencyInfoAnnouncement class])];
                                                            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
                                                        } else {
                                                            NSString *message = [NSString stringWithFormat:@"failed to load announcement from remote server"];
                                                            NSError *error = [NSError errorWithDomain:MITErrorDomain code:MITMobileRequestUnknownError userInfo:@{NSLocalizedDescriptionKey : message}];
                                                            completion(nil,error);
                                                        }
                                                    }
                                                }];
}

@end
