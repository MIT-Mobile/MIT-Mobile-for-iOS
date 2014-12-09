#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttleVehicleList

@dynamic agency;
@dynamic routeId;
@dynamic routeURL;
@dynamic vehicles;
@dynamic scheduled;
@dynamic predictable;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId",
                                                  @"route_url": @"routeURL",
                                                  @"agency": @"agency",
                                                  @"scheduled": @"scheduled",
                                                  @"predictable": @"predictable"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"vehicles" toKeyPath:@"vehicles" withMapping:[MITShuttleVehicle objectMappingFromVehicleList]]];
    [mapping setIdentificationAttributes:@[@"routeId"]];
    return mapping;
}

@end
