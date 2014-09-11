#import "MITNewsCategoryDataSource.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITAdditions.h"
#import "MITNewsModelController.h"

@interface MITNewsCategoryDataSource ()
@property(nonatomic,readwrite,strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic) NSUInteger numberOfObjects;

@property(strong) dispatch_semaphore_t requestSemaphore;
@property(getter=isUpdating) BOOL updating;
@end

@implementation MITNewsCategoryDataSource
@synthesize updating = _updating;

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithManagedObjectContext:managedObjectContext];
    if (self) {
        _requestSemaphore = dispatch_semaphore_create(1);
        [self _updateFetchedResultsController];
    }

    return self;
}

- (NSOrderedSet*)categories
{
    NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];
    [self.objects enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
        if ([object isKindOfClass:[MITNewsCategory class]]) {
            [categories addObject:object];
        } else {
            NSString *reason = [NSString stringWithFormat:@"expected an object of type %@, got %@", NSStringFromClass([MITNewsCategory class]), NSStringFromClass([object class])];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
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
- (void)_updateFetchedResultsController
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
    dispatch_semaphore_t requestSemaphore = self.requestSemaphore;
    NSInteger result = dispatch_semaphore_wait(requestSemaphore, DISPATCH_TIME_NOW);
    if (result) {
        // semaphore wait timed out
        NSError *error = [NSError errorWithDomain:MITErrorDomain code:MITRequestInProgressError userInfo:nil];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(error);
            }
        }];

        DDLogInfo(@"failed to dispatch %@, request already in progress", NSStringFromSelector(_cmd));
        return;
    }

    self.updating = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:MITNewsDataSourceDidBeginUpdatingNotification object:self];

    __weak MITNewsCategoryDataSource *weakSelf = self;
    [[MITNewsModelController sharedController] categories:^(NSArray *categories, NSError *error) {
        MITNewsCategoryDataSource *blockSelf = weakSelf;

        if (!blockSelf) {
            dispatch_semaphore_signal(requestSemaphore);
            return;
        }

        [blockSelf.managedObjectContext performBlock:^{
            if (error) {
                [blockSelf _responseFailedWithError:error];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(error);
                    }
                }];
            } else {
                blockSelf.refreshedAt = [NSDate date];

                [blockSelf _responseFinishedWithObjects:categories];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(nil);
                    }
                }];
            }

            blockSelf.updating = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:MITNewsDataSourceDidEndUpdatingNotification object:self];
            dispatch_semaphore_signal(requestSemaphore);
        }];
    }];
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
    [self _updateFetchedResultsController];
}

@end
