#import "MITNewsModelController.h"

#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

#import "MITNewsRecentSearchList.h"
#import "MITNewsRecentSearchQuery.h"

@interface MITNewsModelController ()
- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString featured:(BOOL)featured offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, NSDictionary *pagingMetadata, NSError *error))block;
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation MITNewsModelController
@synthesize fetchedResultsController = _fetchedResultsController;

+ (instancetype)sharedController
{
    static MITNewsModelController *sharedModelController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedModelController = [[self alloc] init];
    });

    NSAssert(sharedModelController, @"failed to create the shared %@ instance", NSStringFromClass(self));
    return sharedModelController;
}

- (void)categories:(void (^)(NSArray *categories, NSError *error))block
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITNewsCategoriesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (block) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            if (!error) {
                                                                NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                                NSArray *objects = [mainQueueContext transferManagedObjects:[result array]];
                                                                block(objects,nil);
                                                            } else {
                                                                NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                                NSArray *storyObjects = [mainQueueContext transferManagedObjects:self.fetchedResultsController.fetchedObjects];
                                                                block(storyObjects,error);
                                                            }
                                                        }];
                                                    }
                                                }];
}

- (NSFetchRequest*)_fetchRequestForCategory
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsCategory entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
    return fetchRequest;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [self _fetchRequestForCategory];
        NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:mainQueueContext sectionNameKeyPath:nil cacheName:nil];
        
        NSError *fetchError = nil;
        BOOL success = [fetchedResultsController performFetch:&fetchError];
        if (!success) {
            DDLogWarn(@"failed to perform fetch for %@: %@", [self description], fetchError);
        }
        
        _fetchedResultsController = fetchedResultsController;
    }
    
    return _fetchedResultsController;
}

- (void)featuredStoriesWithOffset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, NSDictionary *pagingMetadata, NSError *error))completion
{
    [self storiesInCategory:nil
                      query:nil
                   featured:YES
                     offset:offset
                      limit:limit
                 completion:completion];
}

- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray* stories, NSDictionary *pagingMetadata, NSError* error))completion
{
    [self storiesInCategory:categoryID
                      query:queryString
                   featured:NO
                     offset:offset
                      limit:limit
                 completion:completion];
}

- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString featured:(BOOL)featured offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, NSDictionary *pagingMetadata, NSError *error))block
{
    NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];

    if (queryString) {
        parameters[@"q"] = queryString;
    }

    if (categoryID) {
        parameters[@"category"] = categoryID;
    }

    if (featured) {
        parameters[@"featured"] = @"true";
    }

    if (offset) {
        parameters[@"offset"] = @(offset);
    }

    if (limit) {
        parameters[@"limit"] = @(limit);
    }

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITNewsStoriesResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (!error) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            if (!error) {
                                                                NSManagedObjectContext *mainContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                                NSArray *mainQueueStories = [mainContext transferManagedObjects:[result array]];
                                                                NSDictionary *pagingMetadata = MITPagingMetadataFromResponse(response);
                                                                block(mainQueueStories,pagingMetadata,nil);
                                                            } else {
                                                                block(nil,nil,error);
                                                            }
                                                        }];
                                                    } else {
                                                        DDLogWarn(@"failed to updates 'stories': %@", error);
                                                        
                                                        if (block) {
                                                            block(nil,nil,error);
                                                        }
                                                    }
                                                }];
}

#pragma mark - Recent Search List

- (MITNewsRecentSearchList *)recentSearchListWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsRecentSearchList entityName]];
    NSError *error = nil;

    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        return nil;
    } else if ([fetchedObjects count] == 0) {
        return [[MITNewsRecentSearchList alloc] initWithEntity:[MITNewsRecentSearchList entityDescription] insertIntoManagedObjectContext:context];
    } else {
        return [fetchedObjects firstObject];
    }
}

#pragma mark - Recent Search Items

- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString
{
    NSManagedObjectContext *managedObjectContext = [MITCoreDataController defaultController].mainQueueContext;
    MITNewsRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:managedObjectContext];
    NSArray *recentSearchItems = [[recentSearchList.recentQueries reversedOrderedSet] array];
    if (filterString && ![filterString isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text BEGINSWITH[cd] %@", filterString];
        return [recentSearchItems filteredArrayUsingPredicate:predicate];
    }
    
    return [[recentSearchList.recentQueries reversedOrderedSet] array];
}

- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError *)error
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *updateError) {
        
        MITNewsRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        
        MITNewsRecentSearchQuery *searchItem = [[MITNewsRecentSearchQuery alloc] initWithEntity:[MITNewsRecentSearchQuery entityDescription] insertIntoManagedObjectContext:context];

        if (searchItem) {
            searchItem.text = searchTerm;
            
            NSArray *recentSearchItems = [recentSearchList.recentQueries array];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text = %@", searchItem.text ];
            NSArray *previous = [recentSearchItems filteredArrayUsingPredicate:predicate];
            
            if ([previous count]) {
                [recentSearchList removeRecentQueriesObject:[previous firstObject]];
            }
            
            [recentSearchList addRecentQueriesObject:searchItem];
            
            return YES;
        } else {
            return NO;
        }

    } error:&error];
}

- (void)clearRecentSearchesWithError:(NSError *)error
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *updateError) {
        MITNewsRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        [context deleteObject:recentSearchList];
        recentSearchList = [self recentSearchListWithManagedObjectContext:context];

        if (recentSearchList) {
            return YES;
        } else {
            return NO;
        }
    } error:&error];
}

@end
