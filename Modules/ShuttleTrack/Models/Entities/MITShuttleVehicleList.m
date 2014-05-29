#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttleVehicleList

@dynamic agency;
@dynamic routeId;
@dynamic routeTitle;
@dynamic routeURL;
@dynamic vehicles;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId",
                                                  @"route_url": @"routeURL",
                                                  @"route_title": @"routeTitle",
                                                  @"agency": @"agency"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"vehicles" toKeyPath:@"vehicles" withMapping:[MITShuttleVehicle objectMapping]]];
    [mapping setIdentificationAttributes:@[@"routeId"]];
    return mapping;
}

@end
