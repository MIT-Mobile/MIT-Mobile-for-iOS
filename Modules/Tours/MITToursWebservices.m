#import "MITToursWebservices.h"
#import "MITMobileResources.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITToursWebservices

+ (void)getToursWithCompletion:(void (^)(NSArray *tours, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITToursResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [MITToursWebservices handleResult:result error:error completion:completion];
                                                }];
}

+ (void)handleResult:(RKMappingResult *)result error:(NSError *)error completion:(void (^)(NSArray *tours, NSError *error))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!error) {
            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
            NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
            [mainQueueContext save:nil];
            if (completion) {
                if (objects.count > 0) {
                    completion(objects, nil);
                }
                else {
                    completion(nil, nil);
                }
            }
        } else {
            if (completion) {
                completion(nil, error);
            }
        }
    }];
}

@end
