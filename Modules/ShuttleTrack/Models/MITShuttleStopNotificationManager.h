#import <Foundation/Foundation.h>

@class MITShuttlePrediction;

extern const NSTimeInterval kMITShuttleStopNotificationVariance;
extern const NSTimeInterval kMITShuttleStopNotificationInterval;

@interface MITShuttleStopNotificationManager : NSObject

+ (MITShuttleStopNotificationManager *)sharedManager;
- (void)toggleNotifcationForPrediction:(MITShuttlePrediction *)prediction;
- (void)scheduleNotificationForPrediction:(MITShuttlePrediction *)prediction;
- (void)updateNotificationForPrediction:(MITShuttlePrediction *)prediction;
- (UILocalNotification *)notificationForPrediction:(MITShuttlePrediction *)prediction;

@end
