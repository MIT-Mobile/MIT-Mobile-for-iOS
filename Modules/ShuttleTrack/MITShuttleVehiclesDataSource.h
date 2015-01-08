#import <Foundation/Foundation.h>
#import "MITShuttleDataSource.h"

@interface MITShuttleVehiclesDataSource : MITShuttleDataSource

@property(nonatomic,copy,readonly) NSArray *vehicles;

- (void)updateVehicles:(void(^)(MITShuttleVehiclesDataSource *dataSource, NSError *error))completion;

@end
