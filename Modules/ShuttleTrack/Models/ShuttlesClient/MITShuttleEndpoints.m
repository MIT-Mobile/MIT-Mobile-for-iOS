//
//  MITShuttleEndpoints.m
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "MITShuttleEndpoints.h"
#import "MITShuttleVehicleList.h"
#import "MITShuttleRoute.h"
#import "MITShuttlePredictionList.h"
#import "RealmManager.h"

@implementation MITShuttleBase
- (NSString *)baseUrl {
    return @"http://m.mit.edu/apis/shuttles";
}
@end

@implementation MITShuttleVehicleListEndpoint
- (Class)returnClass {
    return [MITShuttleVehicleList class];
}
- (NSString *)endpointUrl {
    return @"vehicles";
}
@end

@implementation MITShuttleRoutesEndpoint
- (Class)returnClass {
    return [MITShuttleRoute class];
}
- (NSString *)endpointUrl {
    return @"routes/:routeId";
}
- (NSArray *)slugClassMappings {
    PDSlugMapping *routeSlug = [PDSlugMapping slugMappingWithClass:[MITShuttleRoute class]];
    routeSlug[@"routeId"] = @"identifier";
    return @[routeSlug];
}

- (void)getWithCompletion:(void (^)(id, NSError *))completion {
    [super getWithCompletion:^(id object, NSError *error) {
        
        // Need to map tuples, and updated time manually.  This is generally how you would do a manual override.
        NSDate *updated = [NSDate date];
        if (!error) {
            if ([object isKindOfClass:[NSArray class]]) {
                for (MITShuttleRoute *rte in object) {
                    for (MITShuttleStop *stp in rte.stops) {
                        stp.stopAndRouteIdTuple = [NSString stringWithFormat:@"%@,%@", rte.identifier, stp.identifier];
                    }
                    rte.order = [object indexOfObject:rte];
                    rte.updatedTime = updated;
                }
            } else {
                for (MITShuttleStop *stp in [object stops]) {
                    stp.stopAndRouteIdTuple = [NSString stringWithFormat:@"%@,%@", [object identifier], stp.identifier];
                }
                [object setUpdatedTime:updated];
            }
        }
        completion(object, error);
    }];
}
@end

@implementation MITShuttleStopEndpoint
- (Class)returnClass {
    return [MITShuttleStop class];
}
- (NSString *)endpointUrl {
    NSString *superUrl = [super endpointUrl];
    return [NSString stringWithFormat:@"%@/stops/:stopId", superUrl];
}
- (NSArray *)slugClassMappings {
    PDSlugMapping *stopSlug = [PDSlugMapping slugMappingWithClass:[MITShuttleStop class]];
    stopSlug[@"routeId"] = @"routeId";
    stopSlug[@"stopId"] = @"identifier";
    return @[stopSlug];
}
@end

@implementation MITShuttlesPredictionsEndpoint

- (void)getWithCompletion:(void (^)(id object, NSError *error))completion {
    [super getWithCompletion:^(NSArray *predictionLists, NSError *error) {
        if (!error) {
            NSDate *updatedTime = [NSDate date];
            for (MITShuttlePredictionList *list in predictionLists) {
                list.routeAndStopIdTuple = [NSString stringWithFormat:@"%@,%@", list.routeId, list.stopId];
                list.updatedTime = updatedTime;
            }
        }
        completion(predictionLists, error);
    }];
}
- (Class)returnClass {
    return [MITShuttlePredictionList class];
}
- (NSString *)endpointUrl {
    return @"predictions";
}
@end
