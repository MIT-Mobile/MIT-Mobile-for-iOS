#import "MITShuttleStopNotificationManager.h"
#import "MITShuttleStop.h"

NSString * const kMITShuttleStopNotificationStopIdKey = @"kMITShuttleStopNotificationStopIdKey";
NSString * const kMITShuttleStopNotificationPredictionDateKey = @"kMITShuttleStopNotificationPredictionDateKey";
NSString * const kMITShuttleStopNotificationVarianceKey = @"kMITShuttleStopNotificationVarianceKey";

@implementation MITShuttleStopNotificationManager

#pragma mark - Singleton Instance

+ (MITShuttleStopNotificationManager *)sharedManager
{
    static MITShuttleStopNotificationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[MITShuttleStopNotificationManager alloc] init];
    });
    return _sharedManager;
}

- (void)scheduleNotificationForStop:(MITShuttleStop *)stop fromPredictionTime:(NSDate *)date withVariance:(NSTimeInterval)variance
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [date dateByAddingTimeInterval:-300]; // 5 minutes earlier than predicted time
    notification.alertBody = [NSString stringWithFormat:@"The shuttle is arriving at %@ in 5 minutes", stop.title];
    notification.userInfo = @{kMITShuttleStopNotificationStopIdKey: stop.identifier,
                              kMITShuttleStopNotificationPredictionDateKey: date,
                              kMITShuttleStopNotificationVarianceKey: @(variance)};
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)updateNotificationsForStop:(MITShuttleStop *)stop
{
    
}

- (UILocalNotification *)notificationForStop:(MITShuttleStop *)stopToFind nearTime:(NSDate *)dateToFind
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSString *stopId = [notification.userInfo objectForKey:kMITShuttleStopNotificationStopIdKey];
        if ([stopId isEqualToString:stopToFind.identifier]) {
            NSNumber *variance = [notification.userInfo objectForKey:kMITShuttleStopNotificationVarianceKey];
            NSDate *predictionDate = [notification.userInfo objectForKey:kMITShuttleStopNotificationPredictionDateKey];
            if (abs([dateToFind timeIntervalSinceDate:predictionDate]) < [variance doubleValue]) {
                return notification;
            }
        }
    }
    
    return nil;
}

@end
