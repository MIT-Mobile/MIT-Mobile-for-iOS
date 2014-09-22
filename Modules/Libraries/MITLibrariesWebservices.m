#import "MITLibrariesWebservices.h"
#import "MITMobileResources.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITLibrariesLink.h"
#import "MITMobileResources.h"

@implementation MITLibrariesWebservices

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion
{
    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"links" parameters:nil];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];

    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        NSMutableArray *links = [[NSMutableArray alloc] initWithCapacity:[responseObject count]];
        for (NSDictionary *linkDictionary in responseObject) {
            MITLibrariesLink *link = [[MITLibrariesLink alloc] initWithDictionary:linkDictionary];
            [links addObject:link];
        }
        completion(links, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}


+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITLibrariesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    completion(result.array, error);
                                                }];
}

@end