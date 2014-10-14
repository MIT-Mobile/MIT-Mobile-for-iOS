#import "MITDiningWebservices.h"
#import "MITMobileResources.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

@implementation MITDiningWebservices

+ (void)getDiningWithCompletion:(MITDiningCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITDiningResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [MITDiningWebservices handleResult:result error:error completion:completion];
                                                }];
}

+ (void)handleResult:(RKMappingResult *)result error:(NSError *)error completion:(MITDiningCompletionBlock)completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!error) {
            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
            NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
            [mainQueueContext save:nil];
            if (completion) {
                if (objects.count > 0) {
                    completion(objects[0], nil);
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
