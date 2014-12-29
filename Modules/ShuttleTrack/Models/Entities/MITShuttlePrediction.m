#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleStop.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttlePrediction

@dynamic seconds;
@dynamic stopId;
@dynamic timestamp;
@dynamic vehicleId;
@dynamic list;
@dynamic stop;
@dynamic vehicle;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"vehicle_id": @"vehicleId",
                                                  @"timestamp": @"timestamp",
                                                  @"seconds": @"seconds"}];
    [mapping addConnectionForRelationship:@"vehicle" connectedBy:@{@"vehicleId": @"identifier"}];
    [mapping setIdentificationAttributes:@[@"vehicleId", @"timestamp", @"stopId", @"routeId"]];
    return mapping;
}

+ (RKMapping *)objectMappingFromStop
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.id": @"stopId"}];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.route_id": @"routeId"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromPredictionList
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.stop_id": @"stopId"}];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.route_id": @"routeId"}];
//    [mapping addConnectionForRelationship:@"stop" connectedBy:@{@"stopId": @"identifier", @"routeId": @"routeId"}];
    return mapping;
}

@end
