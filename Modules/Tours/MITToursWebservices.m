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

// These are hardcoded for now, but will be replaced by webservice calls when those become available
+ (NSString *)aboutMITText
{
    return @"The misson of MIT is to advance knowledge and educate students in science, technology, and otehr areas of scholarship that will best serve the nation and the world in the 21st century.";
}

+ (NSString *)aboutMITURLString
{
    return @"http://web.mit.edu/institute-events/events/";
}

+ (NSString *)aboutGuidedToursText
{
    return @"Regularly scheduled student-led campus tours are conducted Monday through Friday at 11 am and at 3 pm, excluding legal US holidays and the winter break period.";
}

@end
