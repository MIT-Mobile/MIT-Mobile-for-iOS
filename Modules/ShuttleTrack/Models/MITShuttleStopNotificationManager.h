#import <Foundation/Foundation.h>

@class MITShuttlePrediction, MITShuttlePredictionList, MITShuttleRoute;

extern const NSTimeInterval kMITShuttleStopNotificationVariance;
extern const NSTimeInterval kMITShuttleStopNotificationInterval;

typedef void(^MITShuttleStopNotificationBackgroundFetchCompletionBlock)(NSError *error);

@interface MITShuttleStopNotificationManager : NSObject

+ (MITShuttleStopNotificationManager *)sharedManager;

- (UILocalNotification *)notificationForPrediction:(MITShuttlePrediction *)prediction;

- (void)toggleNotificationForPredictionGroup:(NSArray *)predictionGroup withRouteTitle:(NSString *)routeTitle;
- (void)scheduleNotificationForPredictionGroup:(NSArray *)predictionGroup withRoute:(MITShuttleRoute *)route;
- (void)scheduleNotificationForPredictionGroup:(NSArray *)predictionGroup withRouteTitle:(NSString *)routeTitle;
- (void)updateNotificationsForPredictionList:(MITShuttlePredictionList *)predictionList;

- (void)performBackgroundNotificationUpdatesWithCompletion:(MITShuttleStopNotificationBackgroundFetchCompletionBlock)completion;

@end
