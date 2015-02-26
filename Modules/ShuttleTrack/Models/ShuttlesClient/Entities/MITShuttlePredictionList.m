#import "MITShuttlePredictionList.h"
#import "RealmManager.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"

@implementation MITShuttlePredictionList
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"routeId"] = @"route_id";
    mapping[@"routeURL"] = @"route_url";
    mapping[@"routeTitle"] = @"route_title";
    mapping[@"stopId"] = @"stop_id";
    mapping[@"stopURL"] = @"stop_url";
    mapping[@"stopTitle"] = @"stop_title";
    mapping[@"predictions@MITShuttlePrediction"] = @"predictions";
    return mapping;
}

+ (NSString *)primaryKey {
    return @"routeAndStopIdTuple";
}

// TODO: Reevaluate these, this can definitely be optimized.  You need a stop to get predictions, so we should be able to associate that.
- (MITShuttleStop *)stop {
    return [[self linkingObjectsOfClass:[MITShuttleStop className] forProperty:@"predictionList"] firstObject];
}

- (MITShuttleRoute *)route {
    return self.stop.route;
}
@end