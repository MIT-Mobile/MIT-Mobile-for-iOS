#import "MITShuttleRoute.h"
#import "RealmManager.h"
#import "MITShuttlePredictionList.h"
#import "MITLocationManager.h"

@implementation MITShuttleRoute
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"identifier"] = @"id";
    mapping[@"url"] = @"url";
    mapping[@"title"] = @"title";
    mapping[@"agency"] = @"agency";
    mapping[@"scheduled"] = @"scheduled";
    mapping[@"predictable"] = @"predictable";
    mapping[@"routeDescription"] = @"description";
    mapping[@"pathBoundingBox@MITBoundingBoxTransformer"] = @"path.bbox";
    mapping[@"pathSegments@MITPathSegmentsTransformer"] = @"path.segments";
    mapping[@"stops@MITShuttleStop"] = @"stops";
    mapping[@"predictionsURL"] = @"predictions_url";
    mapping[@"vehiclesURL"] = @"vehicles_url";
    mapping[@"vehicles@MITShuttleVehicle"] = @"vehicles";
    return mapping;
}

+ (NSString *)primaryKey {
    return @"identifier";
}

- (MITShuttleRouteStatus)status
{
    // if our data is stale, we don't know the state of the route
    if ([self.updatedTime timeIntervalSinceNow] < -80) {
        return MITShuttleRouteStatusUnknown;
    }
    
    // `predictable == true` trumps all else. If the route has predictable vehicles, consider it in service regardless of the `scheduled` flag.
    if (self.predictable) {
        return MITShuttleRouteStatusInService;
    }
    // `scheduled` but not `predictable` means it should be running but it's not, which is the unknown status.
    if (self.scheduled) {
        return MITShuttleRouteStatusUnknown;
    }
    // If not `predictable` or `scheduled` then it's not in service, as expected.
    return MITShuttleRouteStatusNotInService;
}

- (NSArray *)nearestStopsWithCount:(NSInteger)count
{
    // TODO: Investigate realm sorting;
    NSMutableArray *stopsArray = [NSMutableArray array];
    for (MITShuttleStop *stop in self.stops) {
        [stopsArray addObject:stop];
    }
    NSArray *sortedStops = [stopsArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MITShuttleStop *stop1 = (MITShuttleStop *)obj1;
        MITShuttleStop *stop2 = (MITShuttleStop *)obj2;
        
        CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake([stop1 latitude], [stop1 longitude]);
        CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake([stop2 latitude], [stop2 longitude]);
        
        MITLocationManager *locationManager = [MITLocationManager sharedManager];
        if ([locationManager milesFromCoordinate:coordinate1] < [locationManager milesFromCoordinate:coordinate2]) {
            return NSOrderedAscending;
        } else if ([locationManager milesFromCoordinate:coordinate1] > [locationManager milesFromCoordinate:coordinate2]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    NSMutableArray *mutableNearestStops = [NSMutableArray arrayWithCapacity:count];
    for (NSInteger stopIndex = 0; stopIndex < count; ++stopIndex) {
        if (stopIndex < [sortedStops count]) {
            [mutableNearestStops addObject:sortedStops[stopIndex]];
        }
    }
    return [NSArray arrayWithArray:mutableNearestStops];
}

@end

//@interface MITBoundingBoxTransformer : JSONMappableTransformer
//@end
//
//@interface MITPathSegmentsTransformer : JSONMappableTransformer
//@end