#import "MITShuttleController.h"
#import "MITCoreData.h"
#import "MITMobileResources.h"
#import "MITAdditions.h"
#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"

@implementation MITShuttleController

#pragma mark - Singleton Instance

+ (MITShuttleController *)sharedController
{
    static MITShuttleController *_sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedController = [[MITShuttleController alloc] init];
    });
    return _sharedController;
}

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - Routes/Stops

- (void)getRoutes:(MITShuttleRoutesCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesRoutesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.array, nil);
                                                    }
                                                }];
}

- (void)getRouteDetail:(MITShuttleRoute *)route completion:(MITShuttleRouteDetailCompletionBlock)completion
{
    NSDictionary *parameters = @{@"route": route.identifier};
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesRouteResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.firstObject, nil);
                                                    }
                                                }];
}

- (void)getStopDetail:(MITShuttleStop *)stop completion:(MITShuttleStopDetailCompletionBlock)completion
{
    NSDictionary *parameters = @{@"route": stop.route.identifier, @"stop": stop.identifier};
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesStopResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.firstObject, nil);
                                                    }
                                                }];
}

#pragma mark - Predictions

- (void)getPredictionsForStops:(NSArray *)stops completion:(MITShuttlePredictionsCompletionBlock)completion
{
    NSString *agency;
    NSMutableString *stopsString = [NSMutableString string];
    for (MITShuttleStop *stop in stops) {
        if (!agency) {
            agency = stop.route.agency;
        }
        [stopsString appendFormat:@"%@,%@", stop.route.identifier, stop.identifier];
        if (stop != stops.lastObject) {
            [stopsString appendString:@";"];
        }
    }
    NSDictionary *parameters = @{@"agency": agency, @"stops": stopsString};
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesPredictionsResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.array, nil);
                                                    }
                                                }];
}

- (void)getPredictionsForStop:(MITShuttleStop *)stop completion:(MITShuttlePredictionsCompletionBlock)completion
{
    NSDictionary *parameters = @{@"agency": stop.route.agency, @"stopNumber": stop.stopNumber};
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesPredictionsResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.array, nil);
                                                    }
                                                }];
}

#pragma mark - Vehicles

- (void)getVehiclesForRoutes:(NSArray *)routes completion:(MITShuttleVehiclesCompletionBlock)completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITShuttlesVehiclesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (error) {
                                                        completion(nil, error);
                                                    } else {
                                                        completion(result.array, nil);
                                                    }
                                                }];
}

@end
