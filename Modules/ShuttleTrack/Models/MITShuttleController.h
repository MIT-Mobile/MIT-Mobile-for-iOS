#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

typedef void(^MITShuttleRoutesCompletionBlock)(NSArray *routes, NSError *error);
typedef void(^MITShuttleRouteDetailCompletionBlock)(MITShuttleRoute *route, NSError *error);
typedef void(^MITShuttleStopDetailCompletionBlock)(MITShuttleStop *stop, NSError *error);
typedef void(^MITShuttlePredictionsCompletionBlock)(NSArray *predictions, NSError *error);
typedef void(^MITShuttleVehiclesCompletionBlock)(NSArray *vehicles, NSError *error);

@interface MITShuttleController : NSObject

+ (MITShuttleController *)sharedController;

- (void)getRoutes:(MITShuttleRoutesCompletionBlock)completion;
- (void)getRouteDetail:(MITShuttleRoute *)route completion:(MITShuttleRouteDetailCompletionBlock)completion;
- (void)getStopDetail:(MITShuttleStop *)stop completion:(MITShuttleStopDetailCompletionBlock)completion;

- (void)getPredictionsForRoute:(MITShuttleRoute *)route completion:(MITShuttlePredictionsCompletionBlock)completion;
- (void)getPredictionsForStop:(MITShuttleStop *)stop completion:(MITShuttlePredictionsCompletionBlock)completion;

- (void)getVehicles:(MITShuttleVehiclesCompletionBlock)completion;
- (void)getVehiclesForRoute:(MITShuttleRoute *)route completion:(MITShuttleVehiclesCompletionBlock)completion;

- (NSArray *)loadDefaultShuttleRoutes;

@end
