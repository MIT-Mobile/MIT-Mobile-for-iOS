#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"

@implementation MITShuttleVehicleList
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"agency"] = @"agency";
    mapping[@"scheduled"] = @"scheduled";
    mapping[@"predictable"] = @"predictable";
    mapping[@"routeId"] = @"route_id";
    mapping[@"routeURL"] = @"route_url";
    mapping[@"vehicles@MITShuttleVehicle"] = @"vehicles";
    return mapping;
}
@end
