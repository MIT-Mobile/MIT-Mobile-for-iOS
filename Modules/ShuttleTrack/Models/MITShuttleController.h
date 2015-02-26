#import <Foundation/Foundation.h>
//#import <RestKit/RestKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;
@class MITShuttlePredictionsRequestData;

typedef void(^MITShuttleRoutesCompletionBlock)(NSArray *routes, NSError *error);
typedef void(^MITShuttleRouteDetailCompletionBlock)(MITShuttleRoute *route, NSError *error);
typedef void(^MITShuttleStopDetailCompletionBlock)(MITShuttleStop *stop, NSError *error);
typedef void(^MITShuttlePredictionsCompletionBlock)(NSArray *predictionLists, NSError *error);
typedef void(^MITShuttleVehiclesCompletionBlock)(NSArray *vehicleLists, NSError *error);

@interface MITShuttleController : NSObject

+ (MITShuttleController *)sharedController;

- (void)getRoutes:(MITShuttleRoutesCompletionBlock)completion;
- (void)getRouteDetail:(MITShuttleRoute *)route completion:(MITShuttleRouteDetailCompletionBlock)completion;
- (void)getStopDetail:(MITShuttleStop *)stop completion:(MITShuttleStopDetailCompletionBlock)completion;

- (void)getPredictionsForRoute:(MITShuttleRoute *)route completion:(MITShuttlePredictionsCompletionBlock)completion;
- (void)getPredictionsForStop:(MITShuttleStop *)stop completion:(MITShuttlePredictionsCompletionBlock)completion;

- (void)getPredictionsForStops:(NSArray *)stops completion:(MITShuttlePredictionsCompletionBlock)completion;
- (void)getPredictionsForPredictionsRequestData:(MITShuttlePredictionsRequestData *)requestData completion:(MITShuttlePredictionsCompletionBlock)completion;

- (void)getVehicles:(MITShuttleVehiclesCompletionBlock)completion;
- (void)getVehiclesForRoute:(MITShuttleRoute *)route completion:(MITShuttleVehiclesCompletionBlock)completion;

- (NSArray *)loadDefaultShuttleRoutes;

@end

@interface MITShuttlePredictionsRequestData : NSObject

@property (nonatomic, readonly) NSArray *agencies;

- (NSArray *)tuplesForAgency:(NSString *)agency;

- (void)addStop:(MITShuttleStop *)stop;
- (void)addTuple:(NSString *)tuple forAgency:(NSString *)agency;

@end
