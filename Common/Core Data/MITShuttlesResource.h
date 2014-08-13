#import "MITMobileManagedResource.h"

@interface MITShuttleRoutesResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITShuttleRouteDetailResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITShuttleStopDetailResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITShuttlePredictionsResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end

@interface MITShuttleVehiclesResource : MITMobileManagedResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;
@end
