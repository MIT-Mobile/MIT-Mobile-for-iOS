#import <CoreData/CoreData.h>
#import "CoreDataManager.h"

#import "MITMapModelController.h"
#import "MobileRequestOperation.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MapSearch.h"

static NSString* const MITMapResourceCategoryTitles = @"categorytitles";
static NSString* const MITMapResourceCategory = @"category";

NSString* const MITMapSearchEntityName = @"MapSearch";

@interface MITMapModelController ()
@property (nonatomic,strong) NSOperationQueue *requestQueue;

- (void)addRecentSearch:(NSString*)queryString;
@end

@implementation MITMapModelController
+ (MITMapModelController*)sharedController
{
    static MITMapModelController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[MITMapModelController alloc] init];
    });
    
    return sharedController;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}

- (void)recentSearches:(MITMapResponse)block
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    
    [context performBlock:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"searchTerm" ascending:YES]];
        
        NSError *fetchError = nil;
        NSArray *searches = [context executeFetchRequest:request
                                                   error:&fetchError];
        
        NSMutableOrderedSet *searchObjectIDs = nil;
        if (fetchError) {
            searchObjectIDs = [[NSMutableOrderedSet alloc] init];
            
            // Used to keep track the normalized variant of each search query
            // to ensure that we only have one of each.
            NSMutableOrderedSet *normalizedTerms = [[NSMutableOrderedSet alloc] init];
            NSMutableArray *duplicateSearches = [[NSMutableArray alloc] init];
            
            // Run through all the search objects and unique them based
            // on their normalized form (same-cased & whitespace and punctuation removed)
            [[searches copy] enumerateObjectsUsingBlock:^(MapSearch *search, NSUInteger idx, BOOL *stop) {
                if ([normalizedTerms containsObject:[search normalizedSearchTerm]]) {
                    [duplicateSearches addObject:search];
                } else {
                    [normalizedTerms addObject:[search normalizedSearchTerm]];
                    [searchObjectIDs addObject:[search objectID]];
                }
            }];
            
            [duplicateSearches enumerateObjectsUsingBlock:^(NSManagedObject *object, NSUInteger idx, BOOL *stop) {
                [context deleteObject:object];
            }];
            
            [context save:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(searchObjectIDs,[NSDate date],YES,fetchError);
            }
        });
    }];
}

- (void)addRecentSearch:(NSString*)queryString
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    
    [context performBlock:^{
        MapSearch *mapSearch = [NSEntityDescription insertNewObjectForEntityForName:MITMapSearchEntityName
                                                             inManagedObjectContext:context];
        mapSearch.searchTerm = queryString;
        mapSearch.date = [NSDate date];
        [context save:nil];
    }];
}

- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMapResponse)block
{
    NSDictionary *parameters = nil;
    if (queryString) {
        parameters = @{@"q" : queryString};
    }
    
    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"search"
                                                                             parameters:parameters];
    
    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
        NSMutableOrderedSet *places = [[NSMutableOrderedSet alloc] init];

        for (NSDictionary *placeData in content) {
            MITMapPlace *place = [[MITMapPlace alloc] initWithDictionary:placeData];
            [places addObject:place];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(places,[NSDate date],YES,error);
            }
        });
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}


- (void)categories:(MITMapResponse)block
{
    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"categorytitles"
                                                                             parameters:nil];
    
    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
        NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];
        
        for (NSDictionary *categoryData in content) {
            MITMapCategory *category = [[MITMapCategory alloc] initWithDictionary:categoryData];
            [categories addObject:category];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(categories, [NSDate date], YES, error);
            }
        });
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}

- (void)places:(MITMapResponse)block
{
    // The v2 API does not support getting a list of all
    // the available 'places' back (a subcategory is required)
    if (block) {
        block(nil,[NSDate date], YES, nil);
    }
}

- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMapResponse)block
{
    NSDictionary *requestParameters = nil;
    if (category) {
        requestParameters = @{@"id" : category.identifier};
    }

    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"category"
                                                                             parameters:requestParameters];

    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
        NSMutableOrderedSet *places = [[NSMutableOrderedSet alloc] init];

        for (NSDictionary *placeData in content) {
            MITMapPlace *place = [[MITMapPlace alloc] initWithDictionary:placeData];
            [places addObject:place];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(places,[NSDate date],YES,error);
            }
        });
    };

    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}

@end
