#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleVehicle.h"
#import "MITLocationManager.h"
#import "MITShuttlePrediction.h"
#import <CoreLocation/CoreLocation.h>

@implementation MITShuttleRoute

@dynamic agency;
@dynamic identifier;
@dynamic order;
@dynamic pathBoundingBox;
@dynamic pathSegments;
@dynamic predictable;
@dynamic predictionsURL;
@dynamic routeDescription;
@dynamic scheduled;
@dynamic title;
@dynamic url;
@dynamic vehiclesURL;
@dynamic stops;
@dynamic vehicles;
@dynamic lastUpdatedTimestamp;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"url": @"url",
                                                  @"title": @"title",
                                                  @"agency": @"agency",
                                                  @"description": @"routeDescription",
                                                  @"scheduled": @"scheduled",
                                                  @"predictable": @"predictable",
                                                  @"path.bbox": @"pathBoundingBox",
                                                  @"path.segments": @"pathSegments",
                                                  @"predictions_url": @"predictionsURL",
                                                  @"vehicles_url": @"vehiclesURL",
                                                  @"@metadata.mapping.collectionIndex": @"order"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"stops" toKeyPath:@"stops" withMapping:[MITShuttleStop objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"vehicles" toKeyPath:@"vehicles" withMapping:[MITShuttleVehicle objectMapping]]];
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

- (NSArray *)nearestStopsWithCount:(NSInteger)count
{
    NSArray *sortedStops = [self.stops sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MITShuttleStop *stop1 = (MITShuttleStop *)obj1;
        MITShuttleStop *stop2 = (MITShuttleStop *)obj2;
        
        CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake([[stop1 latitude] doubleValue], [[stop1 longitude] doubleValue]);
        CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake([[stop2 latitude] doubleValue], [[stop2 longitude] doubleValue]);
        
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

- (MITShuttleRouteStatus)status
{
    // Data over 1 minute old is considered unavailable
    if ([[NSDate date] timeIntervalSince1970] > [self.lastUpdatedTimestamp timeIntervalSince1970] + 60) {
        return MITShuttleRouteStatusPredictionsUnavailable;
    }
    
    if ([self.scheduled boolValue]) {
        return self.predictable ? MITShuttleRouteStatusInService : MITShuttleRouteStatusPredictionsUnavailable;
    } else {
        return MITShuttleRouteStatusNotInService;
    }
}

- (BOOL)isNextStop:(MITShuttleStop *)stop
{
    if (self.status == MITShuttleRouteStatusInService) {
        for (MITShuttleVehicle *vehicle in self.vehicles) {
            if ([stop isEqual:[self nextStopForVehicle:vehicle]]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSArray *)nextStops
{
    NSMutableArray *nextStops = [NSMutableArray array];
    if (self.status == MITShuttleRouteStatusInService) {
        for (MITShuttleVehicle *vehicle in self.vehicles) {
            MITShuttleStop *nextStop = [self nextStopForVehicle:vehicle];
            if (nextStop) {
                [nextStops addObject:nextStop];
            }
        }
    }
    return [NSArray arrayWithArray:nextStops];
}

- (MITShuttleStop *)nextStopForVehicle:(MITShuttleVehicle *)vehicle
{
    NSOrderedSet *stopsForVehicle = [self.stops filteredOrderedSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        MITShuttleStop *stop = (MITShuttleStop *)evaluatedObject;
        return ([stop nextPredictionForVehicle:vehicle] != nil);
    }]];
    NSArray *sortedStopsForVehicle = [stopsForVehicle sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MITShuttlePrediction *prediction1 = [(MITShuttleStop *)obj1 nextPredictionForVehicle:vehicle];
        MITShuttlePrediction *prediction2 = [(MITShuttleStop *)obj2 nextPredictionForVehicle:vehicle];
        return [prediction1.timestamp compare:prediction2.timestamp];
    }];
    return [sortedStopsForVehicle firstObject];
}

@end
