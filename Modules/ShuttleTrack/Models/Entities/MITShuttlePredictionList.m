#import "MITShuttlePredictionList.h"
#import "MITShuttlePrediction.h"


@implementation MITShuttlePredictionList

@dynamic routeId;
@dynamic routeTitle;
@dynamic routeURL;
@dynamic stopId;
@dynamic stopTitle;
@dynamic stopURL;
@dynamic predictions;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId",
                                                  @"route_url": @"routeURL",
                                                  @"route_title": @"routeTitle",
                                                  @"stop_id": @"stopId",
                                                  @"stop_url": @"stopURL",
                                                  @"stop_title": @"stopTitle"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"predictions" toKeyPath:@"predictions" withMapping:[MITShuttlePrediction objectMappingFromPredictionList]]];
    [mapping setIdentificationAttributes:@[@"routeId", @"stopId"]];
    return mapping;
}

@end
