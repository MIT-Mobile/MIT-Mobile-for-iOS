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
            NSArray *sortedStops = [self.stops sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                MITShuttlePrediction *prediction1 = [(MITShuttleStop *)obj1 nextPredictionForVehicle:vehicle];
                MITShuttlePrediction *prediction2 = [(MITShuttleStop *)obj2 nextPredictionForVehicle:vehicle];
                if (prediction1 && prediction2) {
                    return [prediction1.timestamp compare:prediction2.timestamp];
                } else if (prediction1) {
                    return NSOrderedAscending;
                } else if (prediction2) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedSame;
                }
            }];
            if ([stop isEqual:[sortedStops firstObject]]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
