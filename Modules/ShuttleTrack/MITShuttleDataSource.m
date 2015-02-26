#import "MITShuttleDataSource.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleController.h"

NSString* const MITMobileErrorOwnerDeallocatedErrorFormat = @"block execution of %p canceled, owner was prematurely deallocated";
NSUInteger const MITMobileOwnerDeallocatedError = -16000;

NSError* MITDispatcherDeallocatedError(void *block) {
    NSString *errorString = [NSString stringWithFormat:MITMobileErrorOwnerDeallocatedErrorFormat, block];
    NSError *error = [NSError errorWithDomain:MITErrorDomain
                                         code:MITMobileOwnerDeallocatedError
                                     userInfo:@{NSLocalizedDescriptionKey : errorString}];
    
    DDLogCWarn(@"%@",errorString);
    return error;
}

@interface MITShuttleDataSource ()

@end

@implementation MITShuttleDataSource

- (instancetype)init
{
    return [super init];
//    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
//    return [self initWithManagedObjectContext:managedObjectContext];
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

- (NSFetchRequest *)fetchRequest
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass, and it must not call super", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)loadFetchedResultsController
{
    [self.managedObjectContext performBlockAndWait:^{
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self fetchRequest]
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    }];
}

- (NSFetchedResultsController*)fetchedResultsController
{
    if (!_fetchedResultsController) {
        [self loadFetchedResultsController];
    }
    
    return _fetchedResultsController;
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
    __weak MITShuttleDataSource *weakSelf = self;
    [self.fetchedResultsController.managedObjectContext performBlock:^{
        MITShuttleDataSource *blockSelf = weakSelf;
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

- (BOOL)didFetchResults
{
    return (self.fetchedResultsController.fetchedObjects != nil);
}

- (void)_enqueueRequestCompletionBlock:(void (^)(void))block
{
    NSParameterAssert(block);
    
    __weak MITShuttleDataSource *weakSelf = self;
    [self.completionQueue addOperationWithBlock:^{
        MITShuttleDataSource *blockSelf = weakSelf;
        
        if (!blockSelf.fetchedResultsController.fetchedObjects) {
            [self _performFetch:nil];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:block];
    }];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    MITShuttleDataSource *newDataSource = [[[self class] alloc] init];
    newDataSource.fetchDate = self.fetchDate;
    [newDataSource _performFetch:nil];
    
    return newDataSource;
}

@end
