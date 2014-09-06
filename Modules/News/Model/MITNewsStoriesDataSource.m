#import "MITNewsStoriesDataSource.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITAdditions.h"

static const NSUInteger MITNewsStoriesDataSourceDefaultPageSize = 20;

@interface MITNewsStoriesDataSource ()
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) id changeNotificationToken;

@property(nonatomic,strong) NSURL *nextPageURL;


@property (nonatomic,copy) NSOrderedSet *objectIdentifiers;

@property (nonatomic,copy) NSString *query;
@property (nonatomic,copy) NSString *categoryIdentifier;
@property (nonatomic,getter = isFeaturedStorySource) BOOL featuredStorySource;

@property (getter = isRequestInProgress) BOOL requestInProgress;
@end

@implementation MITNewsStoriesDataSource
@synthesize fetchedResultsController = _fetchedResultsController;

+ (BOOL)clearCachedObjectsWithManagedObjectContext:(NSManagedObjectContext*)context error:(NSError**)error
{
    BOOL success = [super clearCachedObjectsWithManagedObjectContext:context error:error];
    if (!success) {
        return NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    NSArray *result = [context executeFetchRequest:fetchRequest error:error];
    if (!result) {
        return NO;
    }
    
    NSMutableDictionary *storiesByCategory = [[NSMutableDictionary alloc] init];
    
    // Run through all the story objects and stash each of them into an array
    // keyed to the name of the category the story is in.
    [result enumerateObjectsUsingBlock:^(MITNewsStory *story, NSUInteger idx, BOOL *stop) {
        NSString *categoryIdentifier = story.category.identifier;
        NSMutableArray *storiesInCategory = storiesByCategory[categoryIdentifier];
        if (!storiesInCategory) {
            storiesInCategory = [[NSMutableArray alloc] init];
            storiesByCategory[categoryIdentifier] = storiesInCategory;
        }
        
        [storiesInCategory addObject:story];
    }];
    
    // Now go through our hash-of-arrays, and delete any objects with an index
    // greater than the default page size
    [storiesByCategory enumerateKeysAndObjectsUsingBlock:^(NSString *categoryIdentifier, NSMutableArray *stories, BOOL *stop) {
        if ([stories count] >= MITNewsStoriesDataSourceDefaultPageSize) {
            NSRange deletionRange = NSMakeRange(MITNewsStoriesDataSourceDefaultPageSize, [stories count] - MITNewsStoriesDataSourceDefaultPageSize);
            
            NSArray *storiesToDelete = [stories objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:deletionRange]];
            [stories removeObjectsInRange:deletionRange];
            [context performBlock:^{
                [storiesToDelete enumerateObjectsUsingBlock:^(NSManagedObject *object, NSUInteger idx, BOOL *stop) {
                    [context deleteObject:object];
                }];
            }];
        }
    }];
    
    return YES;
}

+ (instancetype)featuredStoriesDataSource
{
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = mainQueueContext;

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:privateContext];
    dataSource.featuredStorySource = YES;

    dataSource.changeNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:mainQueueContext queue:nil usingBlock:^(NSNotification *note) {
        [privateContext mergeChangesFromContextDidSaveNotification:note];
    }];


    return dataSource;
}

+ (instancetype)dataSourceForQuery:(NSString*)query
{
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = mainQueueContext;

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:privateContext];
    dataSource.query = query;

    dataSource.changeNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:mainQueueContext queue:nil usingBlock:^(NSNotification *note) {
        [privateContext mergeChangesFromContextDidSaveNotification:note];
    }];

    return dataSource;
}

+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category
{
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = mainQueueContext;

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:privateContext];
    [category.managedObjectContext performBlockAndWait:^{
        dataSource.categoryIdentifier = category.identifier;
    }];
    
    dataSource.changeNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:mainQueueContext queue:nil usingBlock:^(NSNotification *note) {
        [privateContext mergeChangesFromContextDidSaveNotification:note];
    }];

    return dataSource;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithManagedObjectContext:managedObjectContext];

    if (self) {
        self.maximumNumberOfItemsPerPage = 20;
    }

    return self;
}

- (void)dealloc
{
    if (self.changeNotificationToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.changeNotificationToken];
    }
}

- (NSString*)description
{
    NSMutableString *description = [[NSMutableString alloc] init];

    [description appendString:MITNewsStoriesPathPattern];

    if (self.categoryIdentifier) {
        [description appendFormat:@" { %@ : %@ }",@"category",self.categoryIdentifier];
    } else if (self.query) {
        [description appendFormat:@" { %@ : %@ }",@"query",self.query];
    }

    return description;
}

- (NSOrderedSet*)objects
{
    return self.stories;
}

- (NSOrderedSet*)stories
{
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    return [self storiesUsingManagedObjectContext:mainQueueContext];
}

- (NSOrderedSet*)storiesUsingManagedObjectContext:(NSManagedObjectContext*)context
{
    if ([self _canCacheRequest] || ([self.objectIdentifiers count] > 0)){
        NSArray *fetchedObjects = self.fetchedResultsController.fetchedObjects;
        NSUInteger numberOfItems = MAX(self.maximumNumberOfItemsPerPage,[self.objectIdentifiers count]);
        numberOfItems = MIN(numberOfItems,[fetchedObjects count]);
        
        NSRange rangeOfObjectsToReturn = NSMakeRange(0, numberOfItems);
        fetchedObjects = [fetchedObjects objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeOfObjectsToReturn]];
        
        NSArray *storyObjects = [context transferManagedObjects:fetchedObjects];
        
        return [NSOrderedSet orderedSetWithArray:storyObjects];
    } else {
        return nil;
    }
}

- (BOOL)isUpdating
{
    return self.isRequestInProgress;
}

- (BOOL)_canCacheRequest
{
    if (self.isFeaturedStorySource) {
        return NO;
    } else if ([self.query length]) {
        return NO;
    } else {
        return YES;
    }
}

- (NSFetchRequest*)_fetchRequestForDataSource
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsStory entityName]];

    if (![self _canCacheRequest]) {
        // This is either a featured story request or a search request
        NSSet *objectSet = [NSSet setWithSet:[self.objectIdentifiers set]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF in %@",objectSet];
    } else if (self.categoryIdentifier) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category.identifier == %@", self.categoryIdentifier];
    }

    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    return fetchRequest;
}

- (void)_reloadFetchedResultsController
{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [self _fetchRequestForDataSource];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        NSError *fetchError = nil;
        BOOL success = [fetchedResultsController performFetch:&fetchError];
        if (!success) {
            DDLogWarn(@"failed to perform fetch for %@: %@", [self description], fetchError);
        }
        
        _fetchedResultsController = fetchedResultsController;
    }];
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        [self _reloadFetchedResultsController];
    }

    return _fetchedResultsController;
}

- (void)setObjectIdentifiers:(NSOrderedSet *)objectIdentifiers
{
    if (![_objectIdentifiers isEqualToOrderedSet:objectIdentifiers]) {
        _objectIdentifiers = [objectIdentifiers copy];
        [self _reloadFetchedResultsController];
    }
}

- (BOOL)hasNextPage
{
    return (self.nextPageURL != nil);
}

- (void)nextPage:(void(^)(NSError *error))block
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (![self hasNextPage]) {
            return;
        }
        
        __weak MITNewsStoriesDataSource *weakSelf = self;
        [[MITMobile defaultManager] getObjectsForURL:self.nextPageURL completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
            MITNewsStoriesDataSource *blockSelf = weakSelf;
            
            if (!blockSelf) {
                return;
            } else if (error) {
                [blockSelf _responseFailedWithError:error completion:^{
                    if (block) {
                        block(error);
                    }
                }];
            } else {
                NSDictionary *pagingMetadata = MITPagingMetadataFromResponse(response);
                [blockSelf _responseFinishedWithObjects:[result array] pagingMetadata:pagingMetadata completion:^{
                    if (block) {
                        block(error);
                    }
                }];
            }
        }];
    }];
}

- (void)refresh:(void(^)(NSError *error))block
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __weak MITNewsStoriesDataSource *weakSelf = self;
        void (^responseHandler)(NSArray*,NSDictionary*,NSError*) = ^(NSArray *stories, NSDictionary *pagingMetadata, NSError *error) {
            MITNewsStoriesDataSource *blockSelf = weakSelf;
            blockSelf.requestInProgress = NO;
            
            if (!blockSelf) {
                return;
            } else if (error) {
                [blockSelf _responseFailedWithError:error completion:^{
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(error);
                        }
                    }];
                }];
            } else {
                // This is the main difference between a refresh and
                // a next page load. A refresh will nil out the
                // existing story identifiers before processing the data
                // while a next page load will just tack on the results
                // to the existing list of identifiers
                blockSelf.objectIdentifiers = nil;
                self.refreshedAt = [NSDate date];

                [blockSelf _responseFinishedWithObjects:stories pagingMetadata:pagingMetadata completion:^{
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(nil);
                        }
                    }];
                }];
            }
        };

        if (self.isRequestInProgress) {
            return;
        }

        self.requestInProgress = YES;
        if (self.isFeaturedStorySource) {
            [[MITNewsModelController sharedController] featuredStoriesWithOffset:0 limit:self.maximumNumberOfItemsPerPage completion:responseHandler];
        } else if (self.categoryIdentifier) {
            [[MITNewsModelController sharedController] storiesInCategory:self.categoryIdentifier query:nil offset:0 limit:self.maximumNumberOfItemsPerPage completion:responseHandler];
        } else if (self.query) {
            [[MITNewsModelController sharedController] storiesInCategory:nil query:self.query offset:0 limit:self.maximumNumberOfItemsPerPage completion:responseHandler];
        }
    }];

}

- (void)_responseFailedWithError:(NSError*)error completion:(void(^)())block
{
    // If the request failed, don't touch our existing data
    //  set. The objects should still be valid in the cache and
    //  we don't want to start suddenly telling everything we don't
    //  have any objects if the network is flaky.
    if (block) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    }
}

- (void)_responseFinishedWithObjects:(NSArray*)objects pagingMetadata:(NSDictionary*)pagingMetadata completion:(void(^)())block
{
    [self.managedObjectContext performBlock:^{
        NSArray *addedObjectIdentifiers = [NSMutableArray arrayWithArray:[objects valueForKey:@"objectID"]];
        addedObjectIdentifiers = [addedObjectIdentifiers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSManagedObjectID *objectID, NSDictionary *bindings) {
            return [objectID isKindOfClass:[NSManagedObjectID class]];
        }]];

        NSMutableOrderedSet *newObjectIdentifiers = [NSMutableOrderedSet orderedSetWithOrderedSet:self.objectIdentifiers];
        [newObjectIdentifiers addObjectsFromArray:addedObjectIdentifiers];
        self.objectIdentifiers = newObjectIdentifiers;
        
        self.nextPageURL = pagingMetadata[@"next"];
        
        if (block) {
            block();
        }
    }];
}

@end
