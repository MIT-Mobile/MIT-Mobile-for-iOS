#import "MITNewsCategoryDataSource.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITAdditions.h"
#import "MITNewsModelController.h"

@interface MITNewsCategoryDataSource () <NSFetchedResultsControllerDelegate>
@property(nonatomic,readwrite,strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic,readwrite,strong) NSDate *lastRefreshed;

@property(nonatomic) NSUInteger numberOfObjects;
@property(nonatomic,copy) NSOrderedSet *objectIdentifiers;
@property(strong) NSRecursiveLock *requestLock;
@end

@implementation MITNewsCategoryDataSource
- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithManagedObjectContext:managedObjectContext];
    if (self) {
        _requestLock = [[NSRecursiveLock alloc] init];
    }

    return self;
}

- (NSOrderedSet*)categories
{
    NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];
    [self.objects enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
        if ([object isKindOfClass:[MITNewsCategory class]]) {
            [categories addObject:object];
        }
    }];

    return categories;
}

- (NSOrderedSet*)objects
{
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    return [self objectsUsingManagedObjectContext:mainQueueContext];
}

- (NSOrderedSet*)objectsUsingManagedObjectContext:(NSManagedObjectContext*)context
{
    NSArray *categoryObjects = [context transferManagedObjects:self.fetchedResultsController.fetchedObjects];

    return [NSOrderedSet orderedSetWithArray:categoryObjects];
}

#pragma mark Private

#pragma mark Managing the FRC
- (NSFetchedResultsController*)_createFetchedResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    [self _setupFetchRequestForFetchedResultsController:fetchedResultsController];
    return fetchedResultsController;
}

- (void)_reloadFetchedResultsController
{
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchedResultsController *fetchedResultsController = [self _createFetchedResultsController];

        self.fetchedResultsController = fetchedResultsController;
        [self _refreshFetchedResultsController];
    }];
}

- (void)_refreshFetchedResultsController
{
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext reset];

        NSError *fetchError = nil;
        BOOL success = [self.fetchedResultsController performFetch:&fetchError];
        if (!success) {
            DDLogWarn(@"failed to perform fetch for %@: %@", [self description], fetchError);
        }
    }];
}

- (void)_setupFetchRequestForFetchedResultsController:(NSFetchedResultsController*)fetchedResultsController
{
    fetchedResultsController.delegate = self;

    NSFetchRequest *fetchRequest = fetchedResultsController.fetchRequest;
    fetchRequest.entity = [MITNewsCategory entityDescription];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
}

#pragma mark Public
- (void)refresh:(void (^)(NSError *error))block
{
    if ([self.requestLock tryLock]) {
        __weak MITNewsCategoryDataSource *weakSelf = self;
        [[MITNewsModelController sharedController] categories:^(NSArray *categories, NSError *error) {
            MITNewsCategoryDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
            }

            [self.managedObjectContext performBlock:^{
                if (error) {
                    [self _responseFailedWithError:error];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(error);
                        }
                    }];
                } else {
                    blockSelf.objectIdentifiers = nil;
                    [self _responseFinishedWithObjects:categories];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(nil);
                        }
                    }];
                }
            }];
        }];
    } else {
        // Signal back to the block that the request will not be completed
    }
}

- (BOOL)hasNextPage
{
    return NO;
}

- (void)_responseFailedWithError:(NSError*)error
{
    DDLogWarn(@"failed to update categories: %@",error);
}

- (void)_responseFinishedWithObjects:(NSArray*)objects
{
    self.lastRefreshed = [NSDate date];

    NSMutableOrderedSet *addedObjectIdentifiers = [[NSMutableOrderedSet alloc] init];
    [[objects valueForKey:@"objectID"] enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
        if ([objectID isKindOfClass:[NSManagedObjectID class]]) {
            [addedObjectIdentifiers addObject:objectID];
        }
    }];

    NSMutableOrderedSet *allObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:self.objectIdentifiers];
    [allObjects unionOrderedSet:addedObjectIdentifiers];
    self.objectIdentifiers = allObjects;
}

@end
