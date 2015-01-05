#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicle.h"

@interface MITShuttleStop ()

@property (nonatomic, strong) NSString *stopAndRouteIdTuple;

@end

@implementation MITShuttleStop

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic predictionsURL;
@dynamic shortName;
@dynamic stopNumber;
@dynamic name;
@dynamic url;
@dynamic predictionList;
@dynamic route;
@dynamic routeId;

@synthesize stopAndRouteIdTuple = _stopAndRouteIdTuple;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"url": @"url",
                                                  @"title": @"name",
                                                  @"short_title": @"shortName",
                                                  @"stop_number": @"stopNumber",
                                                  @"lat": @"latitude",
                                                  @"lon": @"longitude",
                                                  @"predictions_url": @"predictionsURL"}];
    
    
    [mapping setIdentificationAttributes:@[@"identifier", @"routeId"]];
    [mapping addConnectionForRelationship:@"route" connectedBy:@{@"routeId": @"identifier"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromDetail
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"predictionList" withMapping:[MITShuttlePredictionList objectMappingFromStop]]];
    [mapping addAttributeMappingsFromDictionary:@{@"route_id": @"routeId"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromRoutes
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.id": @"routeId"}];
    return mapping;
}

+ (RKMapping *)objectMappingFromRouteDetail
{
    RKEntityMapping *mapping = (RKEntityMapping *)[self objectMapping];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"predictionList" withMapping:[MITShuttlePredictionList objectMappingFromStop]]];
    [mapping addAttributeMappingsFromDictionary:@{@"@parent.id": @"routeId"}];
    return mapping;
}

- (MITShuttlePrediction *)nextPrediction
{
    return [self.predictionList.predictions firstObject];
}

- (MITShuttlePrediction *)nextPredictionForVehicle:(MITShuttleVehicle *)vehicle
{
    for (MITShuttlePrediction *prediction in self.predictionList.predictions) {
        if ([vehicle isEqual:prediction.vehicle]) {
            return prediction;
        }
    }
    return nil;
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
}

- (NSString *)title
{
    return self.name;
}

#pragma mark - Unique ID

- (NSString *)stopAndRouteIdTuple
{
    if (_stopAndRouteIdTuple == nil) {
        _stopAndRouteIdTuple = [NSString stringWithFormat:@"%@,%@", self.routeId, self.identifier];
    }
    
    return _stopAndRouteIdTuple;
}

@end
