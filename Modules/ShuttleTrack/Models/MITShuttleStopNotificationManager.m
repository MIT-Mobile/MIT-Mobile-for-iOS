#import "MITShuttleStopNotificationManager.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"
#import "MITCoreDataController.h"
#import "CoreData+MITAdditions.h"
#import "MITUnreadNotifications.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttleController.h"

static NSString * const kMITShuttleStopNotificationStopIdKey = @"kMITShuttleStopNotificationStopIdKey";
static NSString * const kMITShuttleStopNotificationVehicleIdKey = @"kMITShuttleStopNotificationVehicleIdKey";
static NSString * const kMITShuttleStopNotificationPredictionDateKey = @"kMITShuttleStopNotificationPredictionDateKey";

// Use 10 minutes variance. Using the length of the route loop isn't accurate since there can be multiple shuttles on a route. 10 minutes is a "best-guess" scenario unless we can find a better way or add support in the api
const NSTimeInterval kMITShuttleStopNotificationVariance = 600.0;
const NSTimeInterval kMITShuttleStopNotificationInterval = -300.0;

@interface MITShuttleStopNotificationManager()

@property (nonatomic, strong) NSMutableArray *predictionLoaders;
@property (nonatomic, strong) MITShuttleStopNotificationBackgroundFetchCompletionBlock backgroundFetchCompletionBlock;

@end

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

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _predictionLoaders = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Notifications

- (void)toggleNotificationForPredictionGroup:(NSArray *)predictionGroup withRouteTitle:(NSString *)routeTitle
{
    MITShuttlePrediction *corePrediction = [predictionGroup firstObject];
    UILocalNotification *scheduledNote = [self notificationForPrediction:corePrediction];
    if (scheduledNote) {
        [[UIApplication sharedApplication] cancelLocalNotification:scheduledNote];
    } else {
        [self scheduleNotificationForPredictionGroup:predictionGroup withRouteTitle:routeTitle];
    }
}

- (void)scheduleNotificationForPredictionGroup:(NSArray *)predictionGroup withRoute:(MITShuttleRoute *)route
{
    [self scheduleNotificationForPredictionGroup:predictionGroup withRouteTitle:route.title];
}

- (void)scheduleNotificationForPredictionGroup:(NSArray *)predictionGroup withRouteTitle:(NSString *)routeTitle
{
    MITShuttlePrediction *rootPrediction = [predictionGroup firstObject];
    NSDate *fireDate = [NSDate dateWithTimeIntervalSince1970:[rootPrediction.timestamp doubleValue] + kMITShuttleStopNotificationInterval];
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[rootPrediction.timestamp doubleValue]];
    
    NSString *alertBody = [self alertBodyForPredictionGroup:predictionGroup withRouteTitle:routeTitle];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertAction = @"View";
    notification.fireDate = fireDate;
    notification.alertBody = alertBody;
    notification.userInfo = @{kMITShuttleStopNotificationStopIdKey:         rootPrediction.stopId,
                              kMITShuttleStopNotificationVehicleIdKey:      rootPrediction.vehicleId,
                              kMITShuttleStopNotificationPredictionDateKey: predictionDate,
                              MITNotificationModuleTagKey : MITModuleTagShuttle};
    UIApplication *application = [UIApplication sharedApplication];
    [application scheduleLocalNotification:notification];
    if (application.backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
}

- (NSString *)alertBodyForPredictionGroup:(NSArray *)predictionGroup withRouteTitle:(NSString *)routeTitle
{
    MITShuttlePrediction *rootPrediction = predictionGroup.firstObject;
    NSMutableString *alertBody = [NSMutableString string];
    [alertBody appendString:routeTitle];
    [alertBody appendString:@" arriving at "];
    [alertBody appendString:rootPrediction.list.stop.title];
    [alertBody appendString:@" in "];
    NSTimeInterval fireDateTimestamp = [rootPrediction.timestamp doubleValue] + kMITShuttleStopNotificationInterval; // 5 minutes earlier than predicted time
    for (int i = 0; i < predictionGroup.count; i++) {
        MITShuttlePrediction *pred = predictionGroup[i];
        NSTimeInterval secondsToPredictionAtTimeOfFire = [pred.timestamp doubleValue] - fireDateTimestamp;
        int minutesToPredictionAtTimeOfFire = secondsToPredictionAtTimeOfFire / 60;
        if (i == predictionGroup.count - 1) {
            if (predictionGroup.count > 1) {
                [alertBody appendString:@"and "];
            }
            [alertBody appendFormat:@"%i %@", minutesToPredictionAtTimeOfFire, minutesToPredictionAtTimeOfFire > 1 ? @"minutes" : @"minute"];
        } else {
            if (predictionGroup.count > 2) {
                [alertBody appendFormat:@"%i, ", minutesToPredictionAtTimeOfFire];
            } else {
                [alertBody appendFormat:@"%i ", minutesToPredictionAtTimeOfFire];
            }
        }
    }
    [alertBody appendString:@"."];
    return alertBody;
}

- (void)updateNotificationsForPredictionList:(MITShuttlePredictionList *)predictionList
{
    for (int i = 0; i < predictionList.predictions.count; i++) {
        MITShuttlePrediction *prediction = predictionList.predictions[i];
        UILocalNotification *note = [self notificationForPrediction:prediction];
        if (note) {
            [[UIApplication sharedApplication] cancelLocalNotification:note];
            
            NSMutableArray *predictionsToInclude = [NSMutableArray array];
            for (int j = i; j < predictionList.predictions.count && predictionsToInclude.count < 3; j++) {
                [predictionsToInclude addObject:predictionList.predictions[j]];
            }
            [self scheduleNotificationForPredictionGroup:predictionsToInclude withRouteTitle:predictionList.stop.route.title];
        }
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
            if (fabs([predictionDate timeIntervalSinceDate:notificationPredicationDate]) < kMITShuttleStopNotificationVariance) {
                return notification;
            }
        }
    }
    
    return nil;
}

#pragma mark - Background Fetch

- (void)performBackgroundNotificationUpdatesWithCompletion:(MITShuttleStopNotificationBackgroundFetchCompletionBlock)completion
{
    NSArray *scheduledLocalNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    
    NSMutableSet *stopIds = [NSMutableSet setWithCapacity:[scheduledLocalNotifications count]];
    for (UILocalNotification *notification in scheduledLocalNotifications) {
        [stopIds addObject:notification.userInfo[kMITShuttleStopNotificationStopIdKey]];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITShuttleStop entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ CONTAINS identifier", stopIds];
    
    MITCoreDataController *coreDataController = [MITCoreDataController defaultController];
    [coreDataController performBackgroundFetch:fetchRequest completion:^(NSOrderedSet *fetchedObjectIDs, NSError *error) {
        if (error) {
            if (completion) {
                completion(error);
            }
        } else if ([fetchedObjectIDs count] == 0) {
            if (completion) {
                completion(nil);
            }
        } else {
            self.backgroundFetchCompletionBlock = completion;
            
            NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            managedObjectContext.persistentStoreCoordinator = coreDataController.persistentStoreCoordinator;
            NSArray *stops = [managedObjectContext objectsWithIDs:[fetchedObjectIDs array]];
            [[MITShuttleController sharedController] getPredictionsForStops:stops completion:^(NSArray *predictionLists, NSError *error) {
                if (self.backgroundFetchCompletionBlock) {
                    self.backgroundFetchCompletionBlock(nil);
                    self.backgroundFetchCompletionBlock = nil;
                }
            }];
        }
    }];
}

@end
