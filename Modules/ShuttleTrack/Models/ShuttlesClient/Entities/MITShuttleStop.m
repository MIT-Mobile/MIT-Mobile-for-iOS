//
//  MITShuttleStop.m
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"
#import "RealmManager.h"
#import "MITShuttlePredictionList.h"

@implementation MITShuttleStop
- (NSMutableDictionary *)mapping {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    mapping[@"identifier"] = @"id";
    mapping[@"url"] = @"url";
    mapping[@"title"] = @"title";
    mapping[@"stopNumber"] = @"stop_number";
    mapping[@"latitude"] = @"lat";
    mapping[@"longitude"] = @"lon";
    mapping[@"predictionsURL"] = @"predictions_url";
    mapping[@"routeURL"] = @"route_url";
    mapping[@"predictionsURL"] = @"predictions_url";
    mapping[@"predictions@MITShuttlePrediction"] = @"predictions";
    return mapping;
}

+ (NSString *)primaryKey {
    return @"stopAndRouteIdTuple";
}

- (NSString *)routeId {
    return [[self.stopAndRouteIdTuple componentsSeparatedByString:@","] firstObject];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"routeURL" : @""};
}

- (MITShuttleRoute *)route {
    return [[self linkingObjectsOfClass:[MITShuttleRoute className] forProperty:@"stops"] firstObject];
}

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

- (MITShuttlePrediction *)nextPrediction {
    return [self.predictionList.predictions firstObject];
}

- (MITShuttlePrediction *)nextPredictionForVehicle:(MITShuttleVehicle *)vehicle
{
    for (MITShuttlePrediction *prediction in self.predictionList.predictions) {
        if ([vehicle.identifier isEqualToString:prediction.vehicleId]) {
            return prediction;
        }
    }
    return nil;
}

@end
