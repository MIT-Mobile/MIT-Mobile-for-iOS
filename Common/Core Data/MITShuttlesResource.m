#import "MITShuttlesResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleVehicleList.h"

@implementation MITShuttleRoutesResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesRoutesResourceName pathPattern:MITShuttlesRoutesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleRoute objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttleRouteDetailResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesRouteResourceName pathPattern:MITShuttlesRoutePathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleRoute objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttleStopDetailResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesStopResourceName pathPattern:MITShuttlesStopPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleStop objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttlePredictionsResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesPredictionsResourceName pathPattern:MITShuttlesPredictionsPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttlePredictionList objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end

@implementation MITShuttleVehiclesResource : MITMobileManagedResource

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super initWithName:MITShuttlesVehiclesResourceName pathPattern:MITShuttlesVehiclesPathPattern managedObjectModel:managedObjectModel];
    if (self) {
        [self addMapping:[MITShuttleVehicleList objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    
    return self;
}

@end