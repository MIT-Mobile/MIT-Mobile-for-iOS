#import "MITShuttlePredictionList.h"
#import "MITShuttlePrediction.h"


@implementation MITShuttlePredictionList

@dynamic routeId;
@dynamic stopId;
@dynamic predictions;
@dynamic updatedTime;
@dynamic stop;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"predictions" toKeyPath:@"predictions" withMapping:[MITShuttlePrediction objectMappingFromPredictionList]]];
    [mapping setIdentificationAttributes:@[@"routeId", @"stopId"]];
    [mapping addConnectionForRelationship:@"stop" connectedBy:@{@"stopId": @"identifier", @"routeId": @"routeId"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromDetail
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"stop_id": @"stopId"}];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromStop
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"stopId"}];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId"}];
    return mapping;
}

@end
