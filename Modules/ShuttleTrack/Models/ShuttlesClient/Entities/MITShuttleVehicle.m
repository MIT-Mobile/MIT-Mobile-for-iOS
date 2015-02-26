#import "MITShuttleVehicle.h"
#import "MITShuttleRoute.h"

@implementation MITShuttleVehicle
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"heading"] = @"heading";
    mapping[@"latitude"] = @"lat";
    mapping[@"longitude"] = @"lon";
    mapping[@"heading"] = @"heading";
    mapping[@"speedKph"] = @"speed_kph";
    mapping[@"secondsSinceReport"] = @"seconds_since_report";
    mapping[@"identifier"] = @"id";
    return mapping;
}

+ (NSString *)primaryKey {
    return @"identifier";
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (NSString *)title
{
    return @"";
//    self.name;
}

- (MITShuttleRoute *)route {
    return [[self linkingObjectsOfClass:[MITShuttleRoute class] forProperty:@"vehicleList"] firstObject];
}

@end
