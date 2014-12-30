#import <CoreData/CoreData.h>
#import "MITShuttleRoutesDataSource.h"

#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleController.h"


typedef void(^MITShuttleRoutesDataSourceCompletionBlock)(MITShuttleRoutesDataSource *dataSource, NSError *error);

static NSString* const MITMobileErrorOwnerDeallocatedErrorFormat = @"block execution of %p canceled, owner was prematurely deallocated";
static NSUInteger const MITMobileOwnerDeallocatedError = -16000;

static NSError* MITDispatcherDeallocatedError(void *block) {
    NSString *errorString = [NSString stringWithFormat:MITMobileErrorOwnerDeallocatedErrorFormat, block];
    NSError *error = [NSError errorWithDomain:MITErrorDomain
                                         code:MITMobileOwnerDeallocatedError
                                     userInfo:@{NSLocalizedDescriptionKey : errorString}];

    DDLogCWarn(@"%@",errorString);
    return error;
}

@interface MITShuttleRoutesDataSource () <NSFetchedResultsControllerDelegate>
@property(nonatomic,readonly) BOOL didFetchResults;
@property(nonatomic,strong) NSDate *fetchDate;
@property(nonatomic,strong) NSError *lastRequestError;

@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic,strong) NSOperationQueue *completionQueue;
@property(nonatomic,getter=isRequestActive) BOOL requestActive;

@end

@implementation MITShuttleRoutesDataSource
- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    self = [super init];

    if (self) {
        _managedObjectContext = managedObjectContext;
        _expiryInterval = 300.;
        _completionQueue = [[NSOperationQueue alloc] init];
        _completionQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    }

    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    MITShuttleRoutesDataSource *newDataSource = [[[self class] alloc] init];
    newDataSource.fetchDate = self.fetchDate;
    [newDataSource _performFetch:nil];

    return newDataSource;
}

- (void)routes:(MITShuttleRoutesDataSourceCompletionBlock)completion
{
    if ([self needsUpdateFromServer] && !self.isRequestActive) {
        self.completionQueue.suspended = YES;
        self.requestActive = YES;

        // Enquing the block first here because, while it is extremely unlikely
        // for the block to not be enqueued before the request completes,
        // but it's better to be a bit paranoid.
        [self _enqueueRequestCompletionBlock:completion];

        __weak MITShuttleRoutesDataSource *weakSelf = self;
        __unsafe_unretained MITShuttleRoutesDataSource *unsafeSelf = self;
        [[MITShuttleController sharedController] getRoutes:^(NSArray *routes, NSError *error) {
            __strong MITShuttleRoutesDataSource *blockSelf = weakSelf;
            if (blockSelf) {
                if (!error) {
                    blockSelf.fetchDate = [NSDate date];

                    [blockSelf _performAsynchronousFetch:^(NSFetchedResultsController *fetchedResultsController, NSError *error) {
                        blockSelf.lastRequestError = error;
                        blockSelf.completionQueue.suspended = NO;
                    }];
                } else {
                    blockSelf.fetchDate = nil;
                    blockSelf.lastRequestError = error;
                    blockSelf.completionQueue.suspended = NO;
                }
            } else {
                DDLogError(@"%@",MITDispatcherDeallocatedError((__bridge void *)(unsafeSelf)));
            }

            [blockSelf.completionQueue addOperationWithBlock:^{
                blockSelf.requestActive = NO;
            }];
        }];
    } else {
        [self _enqueueRequestCompletionBlock:completion];
    }
}

- (BOOL)needsUpdateFromServer
{
    NSDate *expirationDate = (self.fetchDate ? [NSDate dateWithTimeInterval:self.expiryInterval sinceDate:self.fetchDate] : nil);
    NSDate *currentDate = [NSDate date];

    if (!expirationDate) {
        return YES;
    } else {
        return ([expirationDate laterDate:currentDate] == currentDate);
    }
}

- (BOOL)didFetchResults
{
    return (self.fetchedResultsController.fetchedObjects != nil);
}

- (NSArray*)routes
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];

    if (self.fetchedResultsController.fetchedObjects) {
        return [managedObjectContext transferManagedObjects:self.fetchedResultsController.fetchedObjects];
    } else {
        return nil;
    }
}

- (void)_enqueueRequestCompletionBlock:(MITShuttleRoutesDataSourceCompletionBlock)block
{
    NSParameterAssert(block);

    __weak MITShuttleRoutesDataSource *weakSelf = self;
    [self.completionQueue addOperationWithBlock:^{
        MITShuttleRoutesDataSource *blockSelf = weakSelf;

        if (!blockSelf.fetchedResultsController.fetchedObjects) {
            [self _performFetch:nil];
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            block(blockSelf,blockSelf.lastRequestError);
        }];
    }];
}

- (BOOL)_performFetch:(NSError**)error
{
    __block BOOL fetchDidSucceed = NO;
    [self.fetchedResultsController.managedObjectContext performBlockAndWait:^{
        NSError *blockError = nil;
        fetchDidSucceed = [self.fetchedResultsController performFetch:&blockError];

        if (error) {
            (*error) = blockError;
        }
    }];

    return fetchDidSucceed;
}

- (void)_performAsynchronousFetch:(void(^)(NSFetchedResultsController *fetchedResultsController,NSError *error))fetchCompletion
{
    __weak MITShuttleRoutesDataSource *weakSelf = self;
    [self.fetchedResultsController.managedObjectContext performBlock:^{
        MITShuttleRoutesDataSource *blockSelf = weakSelf;
        NSError *fetchError = nil;
        BOOL fetchDidSucceed = [blockSelf _performFetch:&fetchError];

        if (fetchCompletion) {
            if (fetchDidSucceed) {
                fetchCompletion(blockSelf.fetchedResultsController,nil);
            } else {
                fetchCompletion(nil,fetchError);
            }
        }
    }];
}

- (void)loadFetchedResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleRoute entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];


    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _fetchedResultsController.delegate = self;
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        [self loadFetchedResultsController];
    }

    return _fetchedResultsController;
}

#pragma mark - Delegation
#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self _performFetch:nil];
}

@end
