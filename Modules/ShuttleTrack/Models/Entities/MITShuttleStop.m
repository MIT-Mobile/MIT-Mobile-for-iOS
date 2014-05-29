#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttleStop

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic predictionsURL;
@dynamic shortTitle;
@dynamic stopNumber;
@dynamic title;
@dynamic url;
@dynamic predictions;
@dynamic routes;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"url": @"url",
                                                  @"title": @"title",
                                                  @"short_title": @"shortTitle",
                                                  @"stop_number": @"stopNumber",
                                                  @"lat": @"latitude",
                                                  @"lon": @"longitude",
                                                  @"predictions_url": @"predictionsURL"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"predictions" toKeyPath:@"predictions" withMapping:[MITShuttlePrediction objectMapping]]];
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

- (MITShuttlePrediction *)nextPredictionForRoute:(MITShuttleRoute *)route
{
    for (MITShuttlePrediction *prediction in self.predictions) {
        if ([route.vehicles containsObject:prediction.vehicle]) {
            return prediction;
        }
    }
    return nil;
}

- (MITShuttlePrediction *)nextPredictionForVehicle:(MITShuttleVehicle *)vehicle
{
    for (MITShuttlePrediction *prediction in self.predictions) {
        if ([vehicle isEqual:prediction.vehicle]) {
            return prediction;
        }
    }
    return nil;
}

@end
