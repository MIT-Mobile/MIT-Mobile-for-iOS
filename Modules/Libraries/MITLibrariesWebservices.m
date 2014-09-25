#import "MITLibrariesWebservices.h"
#import "MITMobileResources.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITTouchstoneRequestOperation+MITMobileV3.h"
#import "MITLibrariesLink.h"
#import "MITMobileResources.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesUser.h"


static NSString *const kMITLibrariesBaseEndpoint = @"libraries";
static NSString *const kMITLibrariesAccountEndpoint = @"account";
static NSString *const kMITLibrariesSecureEndpointPrefix = @"secure";
static NSString *const kMITLibrariesSearchEndpoint = @"worldcat";

static NSString *const kMITLibrariesErrorDomain = @"MITLibrariesErrorDomain";

static NSString *const kMITLibraryWebservicesModulesKey = @"libraries";
static NSString *const kMITLibraryWebservicesStartIndexKey = @"startIndex";
static NSString *const kMITLibraryWebservicesIDKey = @"id";
static NSString *const kMITLibraryWebservicesSearchKey = @"search";
static NSString *const kMITLibraryWebservicesSearchTermKey = @"q";
static NSString *const kMITLibraryWebservicesDetailsKey = @"detail";
static NSString *const kMITLibraryWebservicesSearchResponseItemsKey = @"items";
static NSString *const kMITLibraryWebservicesSearchResponseNextIndexKey = @"nextIndex";
static NSString *const kMITLibraryWebservicesSearchResponseTotalResultsKey = @"totalResultsCount";

@implementation MITLibrariesWebservices

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion
{
    NSURLRequest *request = [NSURLRequest requestForModule:kMITLibraryWebservicesModulesKey command:@"links" parameters:nil];
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
    
    NSURLRequest *request = [NSURLRequest requestForModule:kMITLibraryWebservicesModulesKey command:kMITLibraryWebservicesSearchKey parameters:parameters];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        NSArray *items = nil;
        NSInteger nextIndex = 0;
        NSInteger totalResults = 0;
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            items = [MITLibrariesWebservices parsedItems:responseObject[kMITLibraryWebservicesSearchResponseItemsKey]];
            nextIndex = [(NSNumber *)(responseObject[kMITLibraryWebservicesSearchResponseNextIndexKey]) integerValue];
            totalResults = [(NSNumber *)(responseObject[kMITLibraryWebservicesSearchResponseTotalResultsKey]) integerValue];
        }
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
        MITLibrariesWorldcatItem *item = [[MITLibrariesWorldcatItem alloc] initWithDictionary:dictionaryItem];
        [items addObject:item];
    }
    
    return items;
}

+ (void)getItemDetailsForItem:(MITLibrariesWorldcatItem *)item completion:(void (^)(MITLibrariesWorldcatItem *item, NSError *error))completion
{
    if (item.identifier) {
        NSDictionary *paramters = @{kMITLibraryWebservicesIDKey : item.identifier};
    
        NSURLRequest *request = [NSURLRequest requestForModule:kMITLibraryWebservicesModulesKey command:kMITLibraryWebservicesDetailsKey parameters:paramters];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
        [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
            MITLibrariesWorldcatItem *newItem = nil;
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                newItem = [[MITLibrariesWorldcatItem alloc] initWithDictionary:responseObject];
            }
            completion(newItem, nil);
        } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
            completion(nil, error);
        }];
        
        [[NSOperationQueue mainQueue] addOperation:requestOperation];

    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kMITLibrariesErrorDomain code:NSURLErrorResourceUnavailable userInfo:@{NSLocalizedDescriptionKey : @"Item not found"}];
        completion(nil, error);
    }
}

+ (void)getUserWithCompletion:(void (^)(MITLibrariesUser *user, NSError *error))completion
{
    NSString *requestEndpointString = [NSString stringWithFormat:@"%@/%@/%@", kMITLibrariesSecureEndpointPrefix, kMITLibrariesBaseEndpoint, kMITLibrariesAccountEndpoint];
    NSURLRequest *request = [MITTouchstoneRequestOperation requestForEndpoint:requestEndpointString parameters:nil];
    
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        MITLibrariesUser *user = [[MITLibrariesUser alloc] initWithDictionary:responseObject];
        completion(user, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [[self MITWebserviceOperationQueue] addOperation:requestOperation];
}

+ (NSOperationQueue *)MITWebserviceOperationQueue
{
    static NSOperationQueue *operationQueue;
    if (!operationQueue) {
        operationQueue = [[NSOperationQueue alloc] init];
    }
    return operationQueue;
}

+ (NSArray *)parseJSONArray:(NSArray *)JSONArray intoObjectsOfClass:(Class)initializableDictionaryClass
{
    if (!JSONArray || ![initializableDictionaryClass conformsToProtocol:@protocol(MITInitializableWithDictionaryProtocol)]) {
        return nil;
    }
    
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDictionary in JSONArray) {
        id parsedObject = [[initializableDictionaryClass alloc] initWithDictionary:objectDictionary];
        [objects addObject:parsedObject];
    }
    return objects;
}

+ (RKISO8601DateFormatter *)librariesDateFormatter
{
    static RKISO8601DateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [RKISO8601DateFormatter defaultISO8601DateFormatter];
    }
    
    return dateFormatter;
}

@end