#import "MITLibrariesWebservices.h"
#import "MITMobileResources.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITLibrariesLink.h"
#import "MITMobileResources.h"
#import "MITLibrariesItem.h"

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
        MITLibrariesItem *item = [[MITLibrariesItem alloc] initWithDictionary:dictionaryItem];
        [items addObject:item];
    }
    
    return items;
}




+ (void)getItemDetailsForItem:(MITLibrariesItem *)item completion:(void (^)(MITLibrariesItem *item, NSError *error))completion
{
    if (item.identifier) {
        NSDictionary *paramters = @{kMITLibraryWebservicesIDKey : item.identifier};
    
        NSURLRequest *request = [NSURLRequest requestForModule:kMITLibraryWebservicesModulesKey command:kMITLibraryWebservicesDetailsKey parameters:paramters];
        MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
        [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, id responseObject) {
            MITLibrariesItem *newItem = nil;
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                newItem = [[MITLibrariesItem alloc] initWithDictionary:responseObject];
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
//    __weak LibrariesBookDetailViewController *weakSelf = self;
//    requestOperation.completeBlock = ^(MITTouchstoneRequestOperation *operation, NSDictionary *content, NSString *contentType, NSError *error) {
//        LibrariesBookDetailViewController *blockSelf = weakSelf;
//        
//        [blockSelf.activityView removeFromSuperview];
//        
//        if (!blockSelf) {
//            return;
//        } else if (error) {
//            [UIAlertView alertViewForError:error withTitle:@"WorldCat Book Details" alertViewDelegate:nil];
//            self.loadingStatus = BookLoadingStatusFailed;
//            return;
//        } else if (![content isKindOfClass:[NSDictionary class]]) {
//            return;
//        } else {
//            [self.book updateDetailsWithDictionary:content];
//            
//            NSMutableArray *bookAttribs = [NSMutableArray array];
//            
//            // title
//            // year; authors
//            [bookAttribs addObject:@{@"label": self.book.title,
//                                     @"subtitle":[self.book yearWithAuthors]}];
//            
//            // format
//            if (self.book.formats.count) {
//                [bookAttribs addObject:@{@"label": @"Format",
//                                         @"subtitle":[self.book.formats componentsJoinedByString:@","]}];
//            }
//            
//            // summary
//            if (self.book.summarys.count) {
//                [bookAttribs addObject:@{@"label": @"Summary",
//                                         @"subtitle":[self.book.summarys componentsJoinedByString:@"; "]}];
//            }
//            
//            // publisher
//            NSArray *addressesWithPublishers = [self.book addressesWithPublishers];
//            if ([addressesWithPublishers count] > 0) {
//                [bookAttribs addObject:@{@"label": @"Publisher",
//                                         @"subtitle":[addressesWithPublishers componentsJoinedByString:@"; "]}];
//            }
//            
//            // edition
//            if (self.book.editions.count) {
//                [bookAttribs addObject:@{@"label": @"Edition",
//                                         @"subtitle":[self.book.editions componentsJoinedByString:@", "]}];
//            }
//            
//            // description
//            if (self.book.extents.count) {
//                [bookAttribs addObject:@{@"label": @"Description",
//                                         @"subtitle":[self.book.extents componentsJoinedByString:@", "]}];
//            }
//            
//            // isbn
//            if (self.book.isbns.count) {
//                [bookAttribs addObject:@{@"label": @"ISBN",
//                                         @"subtitle":[self.book.isbns componentsJoinedByString:@"\n"]}];
//            }
//            
//            self.bookInfo = [NSArray arrayWithArray:bookAttribs];
//            
//            self.loadingStatus = BookLoadingStatusCompleted;
//            [self.tableView reloadData];
//        }
//    };
//    
//    LibrariesModule *librariesModule = (LibrariesModule *)[[MIT_MobileAppDelegate applicationDelegate] moduleForTag:LibrariesTag];
//    librariesModule.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
//    [librariesModule.requestQueue addOperation:requestOperation];

}






@end