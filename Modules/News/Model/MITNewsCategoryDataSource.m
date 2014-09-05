#import "MITNewsCategoryDataSource.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITAdditions.h"
#import "MITNewsModelController.h"

@interface MITNewsCategoryDataSource ()
@property(nonatomic,readwrite,strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic) NSUInteger numberOfObjects;
@property(strong) dispatch_semaphore_t requestMutex;

@property(getter=isUpdating) BOOL updating;
@end

@implementation MITNewsCategoryDataSource
@synthesize updating = _updating;

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithManagedObjectContext:managedObjectContext];
    if (self) {
        _requestMutex = dispatch_semaphore_create(1);
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
    NSInteger result = dispatch_semaphore_wait(self.requestMutex, DISPATCH_TIME_NOW);
    if (result) {
        // Error
        return;
    }

    self.updating = YES;

    __weak MITNewsCategoryDataSource *weakSelf = self;
    [[MITNewsModelController sharedController] categories:^(NSArray *categories, NSError *error) {
        MITNewsCategoryDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
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
            dispatch_semaphore_signal(blockSelf.requestMutex);
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
