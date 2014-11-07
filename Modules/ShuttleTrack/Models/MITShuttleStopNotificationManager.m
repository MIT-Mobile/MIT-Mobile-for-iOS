#import "MITShuttleStopNotificationManager.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStop.h"
#import "MITShuttleStopPredictionLoader.h"
#import "MITCoreDataController.h"
#import "CoreData+MITAdditions.h"
#import "MITUnreadNotifications.h"

static NSString * const kMITShuttleStopNotificationStopIdKey = @"kMITShuttleStopNotificationStopIdKey";
static NSString * const kMITShuttleStopNotificationVehicleIdKey = @"kMITShuttleStopNotificationVehicleIdKey";
static NSString * const kMITShuttleStopNotificationPredictionDateKey = @"kMITShuttleStopNotificationPredictionDateKey";

// Use 10 minutes variance. Using the length of the route loop isn't accurate since there can be multiple shuttles on a route. 10 minutes is a "best-guess" scenario unless we can find a better way or add support in the api
const NSTimeInterval kMITShuttleStopNotificationVariance = 600.0;
const NSTimeInterval kMITShuttleStopNotificationInterval = -300.0;

@interface MITShuttleStopNotificationManager() <MITShuttleStopPredictionLoaderDelegate>

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
                              kMITShuttleStopNotificationPredictionDateKey: predictionDate,
                              MITNotificationModuleTagKey: MITModuleTagShuttle};
    
    UIApplication *application = [UIApplication sharedApplication];
    [application scheduleLocalNotification:notification];
    if (application.backgroundRefreshStatus == UIBackgroundRefreshStatusAvailable) {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
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
            for (MITShuttleStop *stop in stops) {
                // Reloading predictions will implicitly update scheduled notifications
                [self reloadPredictionsForStop:stop];
            }
        }
    }];
}

- (void)reloadPredictionsForStop:(MITShuttleStop *)stop
{
    MITShuttleStopPredictionLoader *predictionLoader = [[MITShuttleStopPredictionLoader alloc] initWithStop:stop];
    predictionLoader.delegate = self;
    [self.predictionLoaders addObject:predictionLoader];
    [predictionLoader reloadPredictions];
}

#pragma mark - MITShuttleStopPredictionLoaderDelegate

- (void)stopPredictionLoaderDidReloadPredictions:(MITShuttleStopPredictionLoader *)loader
{
    if ([self.predictionLoaders containsObject:loader]) {
        [self.predictionLoaders removeObject:loader];
    }
    if ([self.predictionLoaders count] == 0 && self.backgroundFetchCompletionBlock) {
        self.backgroundFetchCompletionBlock(nil);
        self.backgroundFetchCompletionBlock = nil;
    }
}

@end
