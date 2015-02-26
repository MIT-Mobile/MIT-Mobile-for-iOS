#import "MITShuttlePrediction.h"


@implementation MITShuttlePrediction
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"vehicleId"] = @"vehicle_id";
    mapping[@"timestamp"] = @"timestamp";
    mapping[@"seconds"] = @"seconds";
    return mapping;
}

- (MITShuttleVehicle *)vehicle {
    return [[self linkingObjectsOfClass:@"MITShuttleVehicle" forProperty:@"vehicleId"] firstObject];
}

@end
