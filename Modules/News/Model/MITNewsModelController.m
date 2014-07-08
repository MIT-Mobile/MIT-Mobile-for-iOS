#import "MITNewsModelController.h"

#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

#import "MITResultsPager.h"

#import "MITNewsRecentSearchList.h"
#import "MITNewsRecentSearchQuery.h"

@interface MITNewsModelController ()
- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString featured:(BOOL)featured offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, MITResultsPager* pager, NSError *error))block;
@end
@implementation MITNewsModelController
+ (instancetype)sharedController
{
    static MITNewsModelController *sharedModelController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedModelController = [[self alloc] init];
    });

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
                                                                block(nil,error);
                                                            }
                                                        }];
                                                    }
                                                }];
}

- (void)featuredStoriesWithOffset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, MITResultsPager* pager, NSError *error))completion
{
    [self storiesInCategory:nil
                      query:nil
                   featured:YES
                     offset:offset
                      limit:limit
                 completion:completion];
}

- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray* stories, MITResultsPager* pager, NSError* error))completion
{
    [self storiesInCategory:categoryID
                      query:queryString
                   featured:NO
                     offset:offset
                      limit:limit
                 completion:completion];
}

- (void)storiesInCategory:(NSString*)categoryID query:(NSString*)queryString featured:(BOOL)featured offset:(NSInteger)offset limit:(NSInteger)limit completion:(void (^)(NSArray *stories, MITResultsPager* pager, NSError *error))block
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
                                                                MITResultsPager *pager = [MITResultsPager resultsPagerWithResponse:response];
                                                                block(mainQueueStories,pager,nil);
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
    NSError *error;

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
        
        searchItem.text = searchTerm;
        
        [context transferManagedObjects:@[searchItem]];
        
        [recentSearchList addRecentQueriesObject:searchItem];
        
        [context save:updateError];
    } error:&error];
}

- (void)clearRecentSearchesWithError:(NSError *)error
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *updateError) {
        MITNewsRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        [context deleteObject:recentSearchList];
        recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        [context save:updateError];
    } error:&error];
}

@end
