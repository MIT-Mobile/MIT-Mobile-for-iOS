#import "MITShuttleVehicleList.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleRoute.h"

@implementation MITShuttleVehicleList

@dynamic agency;
@dynamic routeId;
@dynamic routeURL;
@dynamic vehicles;
@dynamic route;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"vehicles" toKeyPath:@"vehicles" withMapping:[MITShuttleVehicle objectMappingFromVehicleList]]];
    [mapping setIdentificationAttributes:@[@"routeId"]];
    
    return mapping;
}

+ (RKMapping *)objectMappingFromDetail
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId",
                                                  @"route_url": @"routeURL",
                                                  @"agency": @"agency"}];
    
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"route" withMapping:[MITShuttleRoute objectMappingFromVehicleList]]];
    return mapping;
}

+ (RKMapping *)objectMappingFromRoute
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"routeId",
                                                  @"url": @"routeURL",
                                                  @"agency": @"agency"}];
    return mapping;
}

@end
