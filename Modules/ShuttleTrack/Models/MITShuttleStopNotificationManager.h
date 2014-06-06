#import <Foundation/Foundation.h>

@class MITShuttleStop;

@interface MITShuttleStopNotificationManager : NSObject

+ (MITShuttleStopNotificationManager *)sharedManager;
- (void)scheduleNotificationForStop:(MITShuttleStop *)stop fromPredictionTime:(NSDate *)date withVariance:(NSTimeInterval)variance;
- (void)updateNotificationsForStop:(MITShuttleStop *)stop;
- (UILocalNotification *)notificationForStop:(MITShuttleStop *)stop nearTime:(NSDate *)dateToFind;

@end
