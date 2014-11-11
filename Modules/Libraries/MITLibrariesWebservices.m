#import "MITLibrariesWebservices.h"
#import "MITMobileResources.h"
#import "MITTouchstoneRequestOperation+MITMobileV3.h"
#import "MITLibrariesLink.h"
#import "MITMobileResources.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesUser.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesFormSheetGroup.h"
#import "MITLibrariesFormSheetElement.h"

NSInteger const kMITLibrariesSearchResultsLimit = 20;

static NSString *const kMITLibrariesBaseEndpoint = @"libraries";
static NSString *const kMITLibrariesAccountEndpoint = @"account";
static NSString *const kMITLibrariesSecureEndpointPrefix = @"secure";
static NSString *const kMITLibrariesSearchEndpoint = @"worldcat";

static NSString *const kMITLibrariesErrorDomain = @"MITLibrariesErrorDomain";

static NSString *const kMITLibraryWebservicesModulesKey = @"libraries";
static NSString *const kMITLibraryWebservicesStartIndexKey = @"offset";
static NSString *const kMITLibraryWebservicesLimitKey = @"limit";
static NSString *const kMITLibraryWebservicesIDKey = @"id";
static NSString *const kMITLibraryWebservicesSearchKey = @"search";
static NSString *const kMITLibraryWebservicesSearchTermKey = @"q";
static NSString *const kMITLibraryWebservicesDetailsKey = @"detail";
static NSString *const kMITLibraryWebservicesSearchResponseItemsKey = @"items";
static NSString *const kMITLibraryWebservicesSearchResponseNextIndexKey = @"nextIndex";
static NSString *const kMITLibraryWebservicesSearchResponseTotalResultsKey = @"totalResultsCount";

static NSString *const kMITLibrariesRecentSearchResultsKey = @"kMITLibrariesRecentSearchResultsKey";

static NSString * const kMITLibraryWebservicesFormsKey = @"forms";
static NSString * const kMITLibraryWebservicesAskUsKey = @"askUs";
static NSString * const kMITLibraryWebservicesTellUsKey = @"tellUs";

@implementation MITLibrariesWebservices

#pragma mark - Libraries Webservice Calls

+ (NSDictionary *)formSheetGroupsAsHTMLParametersDictionary:(NSArray *)formSheetGroups
{
    NSMutableDictionary *formDict = [NSMutableDictionary dictionary];
    for (MITLibrariesFormSheetGroup *group in formSheetGroups) {
        for (MITLibrariesFormSheetElement *element in group.elements) {
            if (element.value && element.htmlParameterKey) {
                formDict[element.htmlParameterKey] = element.htmlParameterValue;
            } else if (!element.optional) {
                NSLog(@"ERROR: Required form sheet element has no value! %@", element.title);
            }
        }
    }
    return formDict;
}

+ (void)postTellUsFormForParameters:(NSDictionary *)parameters withCompletion:(void(^)(id responseObject, NSError *error))completion
{
    NSString *requestEndpoint = [NSString stringWithFormat:@"%@/%@/%@/%@", kMITLibrariesSecureEndpointPrefix, kMITLibrariesBaseEndpoint, kMITLibraryWebservicesFormsKey, kMITLibraryWebservicesTellUsKey];
    NSURLRequest *request = [MITTouchstoneRequestOperation requestForEndpoint:requestEndpoint
                                                                   parameters:parameters
                                                             andRequestMethod:MITTOuchstoneRequestOperationRequestMethodPOST];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [[self MITWebserviceOperationQueue] addOperation:requestOperation];
}

+ (void)postAskUsFormForParameters:(NSDictionary *)parameters withCompletion:(void(^)(id responseObject, NSError *error))completion
{
    NSString *requestEndpoint = [NSString stringWithFormat:@"%@/%@/%@/%@", kMITLibrariesSecureEndpointPrefix, kMITLibrariesBaseEndpoint, kMITLibraryWebservicesFormsKey, kMITLibraryWebservicesAskUsKey];
    NSURLRequest *request = [MITTouchstoneRequestOperation requestForEndpoint:requestEndpoint
                                                                   parameters:parameters
                                                             andRequestMethod:MITTOuchstoneRequestOperationRequestMethodPOST];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        completion(responseObject, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [[self MITWebserviceOperationQueue] addOperation:requestOperation];
}

+ (void)getLinksWithCompletion:(void (^)(NSArray *links, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITLibrariesLinksResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    completion(result.array, error);
                                                }];
}

+ (void)getLibrariesWithCompletion:(void (^)(NSArray *libraries, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITLibrariesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    completion(result.array, error);
                                                }];
}

+ (void)getAskUsTopicsWithCompletion:(void (^)(MITLibrariesAskUsModel *askUs, NSError *error))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITLibrariesAskUsResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        completion(result.array.firstObject, error);
    }];
}

+ (void)getResultsForSearch:(NSString *)searchString startingIndex:(NSInteger)startingIndex completion:(void (^)(NSArray *items, NSError *error))completion
{
    [MITLibrariesWebservices addSearchTermToRecents:searchString];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSString stringWithFormat:@"%d", startingIndex] forKey:kMITLibraryWebservicesStartIndexKey];
    [parameters setObject:searchString ? searchString : @"" forKey:kMITLibraryWebservicesSearchTermKey];
    [parameters setObject:[NSString stringWithFormat:@"%d", kMITLibrariesSearchResultsLimit]  forKey:kMITLibraryWebservicesLimitKey];

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITLibrariesSearchResourceName parameters:parameters completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        completion(result.array, error);
    }];
}

+ (void)getItemDetailsForItem:(MITLibrariesWorldcatItem *)item completion:(void (^)(MITLibrariesWorldcatItem *item, NSError *error))completion
{
    if (item.identifier) {
        NSString *requestEndpoint = [NSString stringWithFormat:@"%@/%@/%@", kMITLibrariesBaseEndpoint, kMITLibrariesSearchEndpoint, item.identifier];
        NSURLRequest *request = [MITTouchstoneRequestOperation requestForEndpoint:requestEndpoint
                                                                       parameters:nil
                                                                 andRequestMethod:MITTouchstoneRequestOperationRequestMethodGET];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
        [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
            MITLibrariesWorldcatItem *newItem = [[MITLibrariesWorldcatItem alloc] initWithDictionary:responseObject];
            completion(newItem, nil);
        } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
            completion(nil, error);
        }];
        
        [[self MITWebserviceOperationQueue] addOperation:requestOperation];
    }
    else {
        NSError *error = [[NSError alloc] initWithDomain:kMITLibrariesErrorDomain code:NSURLErrorResourceUnavailable userInfo:@{NSLocalizedDescriptionKey : @"Item not found"}];
        completion(nil, error);
    }
}

+ (void)getUserWithCompletion:(void (^)(MITLibrariesUser *user, NSError *error))completion
{
    NSString *requestEndpoint = [NSString stringWithFormat:@"%@/%@/%@", kMITLibrariesSecureEndpointPrefix, kMITLibrariesBaseEndpoint, kMITLibrariesAccountEndpoint];
    NSURLRequest *request = [MITTouchstoneRequestOperation requestForEndpoint:requestEndpoint
                                                                   parameters:nil
                                                             andRequestMethod:MITTouchstoneRequestOperationRequestMethodGET];
    
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
        MITLibrariesUser *user = [[MITLibrariesUser alloc] initWithDictionary:responseObject];
        completion(user, nil);
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        completion(nil, error);
    }];
    
    [[self MITWebserviceOperationQueue] addOperation:requestOperation];
}

+ (NSArray *)recentSearchStrings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recents = [defaults objectForKey:kMITLibrariesRecentSearchResultsKey];
    
    if (!recents) {
        recents = @[];
    }
    return recents;
}

+ (void)addSearchTermToRecents:(NSString *)searchTerm
{
    NSMutableArray *recents = [[MITLibrariesWebservices recentSearchStrings] mutableCopy];
    
    if (![recents containsObject:searchTerm]) {
        [recents insertObject:searchTerm atIndex:0];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[recents copy] forKey:kMITLibrariesRecentSearchResultsKey];
        [defaults synchronize];
    }
}

+ (void)clearRecentSearches
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kMITLibrariesRecentSearchResultsKey];
    [defaults synchronize];
}

#pragma mark - Helper Methods

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
