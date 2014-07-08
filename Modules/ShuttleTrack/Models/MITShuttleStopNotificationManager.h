#import <Foundation/Foundation.h>

@class MITShuttlePrediction;

extern const NSTimeInterval kMITShuttleStopNotificationVariance;
extern const NSTimeInterval kMITShuttleStopNotificationInterval;

typedef void(^MITShuttleStopNotificationBackgroundFetchCompletionBlock)(NSError *error);

@interface MITShuttleStopNotificationManager : NSObject

+ (MITShuttleStopNotificationManager *)sharedManager;
- (void)toggleNotifcationForPrediction:(MITShuttlePrediction *)prediction;
- (void)scheduleNotificationForPrediction:(MITShuttlePrediction *)prediction;
- (void)updateNotificationForPrediction:(MITShuttlePrediction *)prediction;
- (UILocalNotification *)notificationForPrediction:(MITShuttlePrediction *)prediction;

- (void)performBackgroundNotificationUpdatesWithCompletion:(MITShuttleStopNotificationBackgroundFetchCompletionBlock)completion;

@end
