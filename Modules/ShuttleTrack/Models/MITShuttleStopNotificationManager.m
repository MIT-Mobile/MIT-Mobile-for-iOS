#import "MITShuttleStopNotificationManager.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStop.h"

static NSString * const kMITShuttleStopNotificationStopIdKey = @"kMITShuttleStopNotificationStopIdKey";
static NSString * const kMITShuttleStopNotificationVehicleIdKey = @"kMITShuttleStopNotificationVehicleIdKey";
static NSString * const kMITShuttleStopNotificationPredictionDateKey = @"kMITShuttleStopNotificationPredictionDateKey";

// Use 10 minutes variance. Using the length of the route loop isn't accurate since there can be multiple shuttles on a route. 10 minutes is a "best-guess" scenario unless we can find a better way or add support in the api
const NSTimeInterval kMITShuttleStopNotificationVariance = 600.0;
const NSTimeInterval kMITShuttleStopNotificationInterval = -300.0;

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

- (void)toggleNotifcationForPrediction:(MITShuttlePrediction *)prediction
{
    UILocalNotification *scheduledNotification = [self notificationForPrediction:prediction];
    if (scheduledNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:scheduledNotification];
    } else {
        [self scheduleNotificationForPrediction:prediction];
    }
}

- (void)scheduleNotificationForPrediction:(MITShuttlePrediction *)prediction
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
    notification.fireDate = [predictionDate dateByAddingTimeInterval:kMITShuttleStopNotificationInterval]; // 5 minutes earlier than predicted time
    notification.alertBody = [NSString stringWithFormat:@"The shuttle is arriving at %@ in %d minutes", prediction.stop.title, abs(kMITShuttleStopNotificationInterval / 60)];
    notification.userInfo = @{kMITShuttleStopNotificationStopIdKey:         prediction.stopId,
                              kMITShuttleStopNotificationVehicleIdKey:      prediction.vehicleId,
                              kMITShuttleStopNotificationPredictionDateKey: predictionDate};
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)updateNotificationForPrediction:(MITShuttlePrediction *)prediction
{
    UILocalNotification *notification = [self notificationForPrediction:prediction];
    if (notification) {
        [[UIApplication sharedApplication] cancelLocalNotification:notification];
        NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
        notification.fireDate = [predictionDate dateByAddingTimeInterval:kMITShuttleStopNotificationInterval];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (UILocalNotification *)notificationForPrediction:(MITShuttlePrediction *)prediction
{
    for (UILocalNotification *notification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        NSString *stopId = notification.userInfo[kMITShuttleStopNotificationStopIdKey];
        NSString *vehicleId = notification.userInfo[kMITShuttleStopNotificationVehicleIdKey];
        if ([stopId isEqualToString:prediction.stopId] && [vehicleId isEqualToString:prediction.vehicleId]) {
            NSDate *notificationPredicationDate = notification.userInfo[kMITShuttleStopNotificationPredictionDateKey];
            NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
            if (abs([predictionDate timeIntervalSinceDate:notificationPredicationDate]) < kMITShuttleStopNotificationVariance) {
                return notification;
            }
        }
    }
    
    return nil;
}

@end
