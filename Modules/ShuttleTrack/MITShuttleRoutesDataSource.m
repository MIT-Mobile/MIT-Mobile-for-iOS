#import <CoreData/CoreData.h>
#import "MITShuttleRoutesDataSource.h"

#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttleController.h"

@interface MITShuttleRoutesDataSource ()

@end

@implementation MITShuttleRoutesDataSource

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.expiryInterval = 60.0;
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleRoute entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
    return fetchRequest;
}

- (NSArray*)routes
{
    if (self.fetchedResultsController.fetchedObjects) {
        NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
        return [managedObjectContext transferManagedObjects:self.fetchedResultsController.fetchedObjects];
    } else {
        return nil;
    }
}

- (void)updateRoutes:(void(^)(MITShuttleRoutesDataSource *dataSource, NSError *error))completion
{
    __weak MITShuttleRoutesDataSource *weakSelf = self;
    void(^enqueueableCompletionBlock)(void) = ^{
        completion(weakSelf, weakSelf.lastRequestError);
    };
    
    if ([self needsUpdateFromServer] && !self.isRequestActive) {
        self.completionQueue.suspended = YES;
        self.requestActive = YES;

        // Enquing the block first here because, while it is extremely unlikely
        // for the block to not be enqueued before the request completes,
        // but it's better to be a bit paranoid.
        [self _enqueueRequestCompletionBlock:enqueueableCompletionBlock];
        
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
        [self _enqueueRequestCompletionBlock:enqueueableCompletionBlock];
    }
}

@end
