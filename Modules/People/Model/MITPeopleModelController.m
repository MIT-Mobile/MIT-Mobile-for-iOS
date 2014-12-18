#import "MITPeopleModelController.h"
#import "MITCoreDataController.h"
#import "PeopleRecentSearchTermList.h"
#import "PeopleRecentSearchTerm.h"

@implementation MITPeopleModelController

+ (instancetype)sharedController
{
    static MITPeopleModelController *sharedModelController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedModelController = [[self alloc] init];
    });
    
    NSAssert(sharedModelController, @"failed to create the shared %@ instance", NSStringFromClass(self));
    
    return sharedModelController;
}

- (NSArray *)recentSearchTermsWithFilterString:(NSString *)filterString
{
    NSManagedObjectContext *managedObjectContext = [MITCoreDataController defaultController].mainQueueContext;
    PeopleRecentSearchTermList *recentSearchList = [self recentSearchListWithManagedObjectContext:managedObjectContext];
    
    NSArray *recentSearchTermsArray = [[recentSearchList.recentSearchTermList reversedOrderedSet] array];
    
    if (filterString && [filterString length] > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recentSearchTerm BEGINSWITH[cd] %@", filterString];
        return [recentSearchTermsArray filteredArrayUsingPredicate:predicate];
    }
    
    return recentSearchTermsArray;
}

- (void)addRecentSearchTerm:(NSString *)searchTermText error:(NSError *)error
{
    if( !searchTermText ) return;
    
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError **updateError) {
        
        PeopleRecentSearchTermList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        
        PeopleRecentSearchTerm *recentSearchItem = [[PeopleRecentSearchTerm alloc] initWithEntity:[PeopleRecentSearchTerm entityDescription] insertIntoManagedObjectContext:context];
        
        if( recentSearchItem == nil ) return NO;
        
        NSArray *recentSearchItemsArray = [recentSearchList.recentSearchTermList array];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recentSearchTerm = %@", searchTermText ];
        NSArray *previouslyEnteredTermArray = [recentSearchItemsArray filteredArrayUsingPredicate:predicate];
        
        // removing the duplicate if any, so that the new one can appear at the top of the list.
        if ([previouslyEnteredTermArray count])
        {
            PeopleRecentSearchTerm *termObj = [previouslyEnteredTermArray firstObject];
            termObj.listOfRecentSearchTerms = nil;
            termObj = nil;
        }
        
        recentSearchItem.recentSearchTerm = searchTermText;
        recentSearchItem.listOfRecentSearchTerms = recentSearchList;
        return YES;
    } error:&error];
}

- (void)clearRecentSearchTermsWithError:(NSError *)error
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *error) {
        
        PeopleRecentSearchTermList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        [context deleteObject:recentSearchList];
        return YES;
    } error:&error];
}

- (PeopleRecentSearchTermList *)recentSearchListWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[PeopleRecentSearchTermList entityName]];
    
    NSError *error = nil;
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if( error ) return nil;
    
    if ([fetchedObjects count] == 0)
    {
        return [[PeopleRecentSearchTermList alloc] initWithEntity:[PeopleRecentSearchTermList entityDescription] insertIntoManagedObjectContext:context];
    }

    return [fetchedObjects firstObject];
}

@end
