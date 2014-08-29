#import "MITNewsCategoryDataSource.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITAdditions.h"
#import "MITNewsModelController.h"

@interface MITNewsCategoryDataSource ()
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
        [self _setupFetchedResultsController];
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
- (void)_setupFetchedResultsController
{
    [self.managedObjectContext performBlockAndWait:^{
        if (!_fetchedResultsController) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                       managedObjectContext:self.managedObjectContext
                                                                                                         sectionNameKeyPath:nil
                                                                                                                  cacheName:nil];
            _fetchedResultsController = fetchedResultsController;
        }

        NSError *fetchError = nil;
        BOOL success = [_fetchedResultsController performFetch:&fetchError];
        if (!success) {
            DDLogWarn(@"failed to perform fetch for %@: %@", [self description], fetchError);
        }
    }];
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
    [self _setupFetchedResultsController];
}

@end
