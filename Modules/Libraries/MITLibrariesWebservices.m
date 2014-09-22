#import "MITLibrariesWebservices.h"
#import "MITMobileResources.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITLibrariesLink.h"
#import "MITMobileResources.h"
#import "MITLibrariesItem.h"

static NSString *const kMITLibraryWebservicesStartIndexKey = @"startIndex";
static NSString *const kMITLibraryWebservicesSearchTermKey = @"q";
static NSString *const kMITLibraryWebservicesSearchResponseItemsKey = @"items";
static NSString *const kMITLibraryWebservicesSearchResponseNextIndexKey = @"nextIndex";
static NSString *const kMITLibraryWebservicesSearchResponseTotalResultsKey = @"totalResultsCount";



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

+ (void)getResultsForSearch:(NSString *)searchString startingIndex:(NSInteger)startingIndex completion:(void (^)(NSArray *items, NSInteger nextIndex, NSInteger totalResults,  NSError *error))completion
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    if (startingIndex != 0) {
        [parameters setObject:[NSString stringWithFormat:@"%d", startingIndex] forKey:kMITLibraryWebservicesStartIndexKey];
    }
    [parameters setObject:searchString ? searchString : @"" forKey:kMITLibraryWebservicesSearchTermKey];
    
    NSURLRequest *request = [NSURLRequest requestForModule:@"libraries" command:@"search" parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        NSArray *items = [MITLibrariesWebservices parsedItems:responseObject[kMITLibraryWebservicesSearchResponseItemsKey]];
        NSInteger nextIndex = [(NSNumber *)(responseObject[kMITLibraryWebservicesSearchResponseNextIndexKey]) integerValue];
        NSInteger totalResults = [(NSNumber *)(responseObject[kMITLibraryWebservicesSearchResponseTotalResultsKey]) integerValue];
        
        completion(items, nextIndex, totalResults, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, 0, 0, error);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

+ (NSArray *)parsedItems:(NSArray *)responseItems
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:responseItems.count];
    for (NSDictionary *dictionaryItem in responseItems) {
        MITLibrariesItem *item = [[MITLibrariesItem alloc] initWithDictionary:dictionaryItem];
        [items addObject:item];
    }
    
    return items;
}


@end