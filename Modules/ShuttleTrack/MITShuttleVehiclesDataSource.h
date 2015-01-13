#import <Foundation/Foundation.h>
#import "MITShuttleDataSource.h"

@class MITShuttleRoute;

@interface MITShuttleVehiclesDataSource : MITShuttleDataSource

@property (nonatomic, copy, readonly) NSArray *vehicles;
@property (nonatomic, strong) MITShuttleRoute *route;
@property (nonatomic, assign) BOOL forceUpdateAllVehicles;

- (void)updateVehicles:(void(^)(MITShuttleVehiclesDataSource *dataSource, NSError *error))completion;
- (void)fetchVehiclesWithoutUpdating:(void(^)(MITShuttleVehiclesDataSource *dataSource, NSError *error))completion;

@end
