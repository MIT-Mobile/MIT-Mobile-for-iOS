#import "MITShuttleVehiclesDataSource.h"
#import <CoreData/CoreData.h>
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleController.h"
#import "MITShuttleRoute.h"

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

- (void)setRoute:(MITShuttleRoute *)route
{
    if ([route isEqual:_route]) {
        return;
    }
    
    _route = route;
    
    // Force recreate fetch results controller next time we fetch
    self.fetchedResultsController = nil;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleVehicle entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    NSPredicate *predicate = nil;
    if (self.route) {
        predicate = [NSPredicate predicateWithFormat:@"route = %@", self.route];
    }
    fetchRequest.predicate = predicate;
    return fetchRequest;
}

- (NSArray*)vehicles
{
    if (self.fetchedResultsController.fetchedObjects) {
        NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
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
        
        void(^vehiclesRequestCompletion)(NSArray *vehicleLists, NSError *error) = ^void(NSArray *vehicleLists, NSError *error) {
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
        };
        
        if (self.route == nil || self.forceUpdateAllVehicles) {
            [[MITShuttleController sharedController] getVehicles:^(NSArray *vehicleLists, NSError *error) {
                vehiclesRequestCompletion(vehicleLists, error);
            }];
        } else {
            [[MITShuttleController sharedController] getVehiclesForRoute:self.route completion:^(NSArray *vehicleLists, NSError *error) {
                vehiclesRequestCompletion(vehicleLists, error);
            }];
        }
    } else {
        [self _enqueueRequestCompletionBlock:enqueueableCompletionBlock];
    }
}

- (void)fetchVehiclesWithoutUpdating:(void(^)(MITShuttleVehiclesDataSource *dataSource, NSError *error))completion
{
    if (completion == nil) {
        return;
    }
    
    [self _performAsynchronousFetch:^(NSFetchedResultsController *fetchedResultsController, NSError *error) {
        completion(self, error);
    }];
}

@end
