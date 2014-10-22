#import "MITToursWebservices.h"
#import "MITMobileResources.h"
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITToursTour.h"

@implementation MITToursWebservices

+ (void)getToursWithCompletion:(void (^)(id object, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITToursResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [MITToursWebservices handleResult:result error:error completion:completion returnObjectShouldBeArray:YES];
                                                }];
}

+ (void)getTourDetailForTour:(MITToursTour *)tour completion:(void (^)(id object, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForURL:[NSURL URLWithString: tour.url]
                                      completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        [MITToursWebservices handleResult:result error:error completion:completion returnObjectShouldBeArray:NO];
    }];
}

+ (void)handleResult:(RKMappingResult *)result error:(NSError *)error completion:(void (^)(id object, NSError *error))completion returnObjectShouldBeArray:(BOOL)alwaysReturnArray
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (!error) {
            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
            NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
            if (completion) {
                if (alwaysReturnArray || ([objects count] > 1 && alwaysReturnArray)) {
                    completion(objects, nil);
                } else {
                    completion([objects firstObject], nil);
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
