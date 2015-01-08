#import "MITShuttleVehiclesDataSource.h"
#import <CoreData/CoreData.h>
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleController.h"

@interface MITShuttleVehiclesDataSource ()

@end

@implementation MITShuttleVehiclesDataSource

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.expiryInterval = 5.0;
    }
    
    return self;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleVehicle entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    return fetchRequest;
}

- (NSArray*)vehicles
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
    
    if (self.fetchedResultsController.fetchedObjects) {
        return [managedObjectContext transferManagedObjects:self.fetchedResultsController.fetchedObjects];
    } else {
        return nil;
    }
}

- (void)updateVehicles:(void(^)(MITShuttleVehiclesDataSource *dataSource, NSError *error))completion
{
    __weak MITShuttleVehiclesDataSource *weakSelf = self;
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
        
        __unsafe_unretained MITShuttleVehiclesDataSource *unsafeSelf = self;
        
        [[MITShuttleController sharedController] getVehicles:^(NSArray *vehicles, NSError *error) {
            __strong MITShuttleVehiclesDataSource *blockSelf = weakSelf;
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
