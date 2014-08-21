#import "MITNewsStoriesDataSource.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITAdditions.h"

@interface MITNewsStoriesDataSource ()
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSURL *nextPageURL;

@property (nonatomic,copy) NSOrderedSet *objectIdentifiers;

@property (nonatomic,copy) NSString *query;
@property (nonatomic,copy) NSString *categoryIdentifier;
@property (nonatomic,getter = isFeaturedStorySource) BOOL featuredStorySource;
@end

@implementation MITNewsStoriesDataSource
@synthesize fetchedResultsController = _fetchedResultsController;

+ (instancetype)featuredStoriesDataSource
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];
    dataSource.featuredStorySource = YES;

    return dataSource;
}

+ (instancetype)dataSourceForQuery:(NSString*)query
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];
    dataSource.query = query;

    return dataSource;
}

+ (instancetype)dataSourceForCategory:(MITNewsCategory*)category
{
    NSManagedObjectContext *context = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];

    MITNewsStoriesDataSource *dataSource = [[self alloc] initWithManagedObjectContext:context];

    [category.managedObjectContext performBlockAndWait:^{
        dataSource.categoryIdentifier = category.identifier;
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
    if (!([self _canCacheRequest] || [self.objectIdentifiers count])) {
        return nil;
    } else {
        [self.fetchedResultsController performFetch:nil];
        NSArray *storyObjects = [context transferManagedObjects:self.fetchedResultsController.fetchedObjects];

        return [NSOrderedSet orderedSetWithArray:storyObjects];
    }
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
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsStory entityName]];

    if (![self _canCacheRequest]) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF in %@",self.objectIdentifiers];
    } else if (self.categoryIdentifier) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category.identifier == %@", self.categoryIdentifier];
    }

    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    return fetchRequest;
}

- (void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [self _fetchRequestForDataSource];
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];

        NSError *fetchError = nil;
        BOOL success = [fetchedResultsController performFetch:&fetchError];
        if (!success) {
            DDLogWarn(@"failed to perform fetch for %@: %@", [self description], fetchError);
        }

        _fetchedResultsController = fetchedResultsController;
    }

    return _fetchedResultsController;
}

- (void)setObjectIdentifiers:(NSOrderedSet *)objectIdentifiers
{
    if (![_objectIdentifiers isEqualToOrderedSet:objectIdentifiers]) {
        _objectIdentifiers = [objectIdentifiers copy];

        if (![self _canCacheRequest]) {
            [self resetFetchedResultsController];
        }
    }
}

- (BOOL)hasNextPage
{
    return (self.nextPageURL != nil);
}

- (BOOL)nextPage:(void(^)(NSError *error))block
{
    if (![self hasNextPage]) {
        return NO;
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

    return YES;
}

- (void)refresh:(void(^)(NSError *error))block
{
    NSString *category = nil;
    NSString *query = nil;

    __weak MITNewsStoriesDataSource *weakSelf = self;
    void (^responseHandler)(NSArray*,NSDictionary*,NSError*) = ^(NSArray *stories, NSDictionary *pagingMetadata, NSError *error) {
        MITNewsStoriesDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else if (error) {
            [self _responseFailedWithError:error completion:^{
                if (block) {
                    block(error);
                }
            }];
        } else {
            // This is the main difference between a refresh and
            // a next page load. A refresh will nil out the
            // existing story identifiers before processing the data
            // while a next page load will just tack on the results
            // to the existing list of identifiers
            blockSelf.objectIdentifiers = nil;

            [self _responseFinishedWithObjects:stories pagingMetadata:pagingMetadata completion:^{
                if (block) {
                    block(nil);
                }
            }];
        }
    };

    if (self.isFeaturedStorySource) {
        [[MITNewsModelController sharedController] featuredStoriesWithOffset:0 limit:self.maximumNumberOfItemsPerPage completion:responseHandler];
    } else {
        if (self.categoryIdentifier) {
            category = self.categoryIdentifier;
        } else if (self.query) {
            query = self.query;
        }

        [[MITNewsModelController sharedController] storiesInCategory:category query:query offset:0 limit:self.maximumNumberOfItemsPerPage completion:responseHandler];
    }

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
    self.nextPageURL = pagingMetadata[@"next"];

    NSMutableOrderedSet *objectIdentifiers = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.objectIdentifiers];

    NSArray *newObjectIdentifiers = [objects valueForKey:@"objectID"];
    [newObjectIdentifiers enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
        if ([objectID isEqual:[NSNull null]]) {
            return;
        } else {
            NSAssert([objectID isKindOfClass:[NSManagedObjectID class]],@"expected an instance of %@ but got a %@",NSStringFromClass([NSManagedObjectID class]),NSStringFromClass([objectID class]));

            [objectIdentifiers addObject:objectID];
        }
    }];

    self.objectIdentifiers = objectIdentifiers;

    if (block) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    }
}

@end
