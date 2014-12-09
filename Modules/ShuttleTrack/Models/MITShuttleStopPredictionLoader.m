#import "MITShuttleStopPredictionLoader.h"
#import "MITShuttleController.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"
#import "MITShuttlePredictionList.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStopNotificationManager.h"

static const NSTimeInterval kStopPredictionDefaultRefreshInterval = 10.0;

@interface MITShuttleStopPredictionLoader()

@property (nonatomic, copy) NSDictionary *predictionsByRoute;
@property (nonatomic, strong) NSTimer *refreshTimer;

@end

@implementation MITShuttleStopPredictionLoader

#pragma mark - Init

- (instancetype)initWithStop:(MITShuttleStop *)stop
{
    self = [super init];
    if (self) {
        _stop = stop;
        _refreshInterval = kStopPredictionDefaultRefreshInterval;
        _shouldRefreshPredictions = YES;
    }
    return self;
}

#pragma mark - Refresh Timer

- (void)startRefreshingPredictions
{
    [self reloadPredictions];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshTimer invalidate];
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval
                                                                 target:self
                                                               selector:@selector(reloadPredictions)
                                                               userInfo:nil
                                                                repeats:YES];
    });
}

- (void)stopRefreshingPredictions
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    });
}

- (void)setShouldRefreshPredictions:(BOOL)shouldRefreshPredictions
{
    _shouldRefreshPredictions = shouldRefreshPredictions;
    if (shouldRefreshPredictions) {
        [self startRefreshingPredictions];
    } else {
        [self stopRefreshingPredictions];
    }
}

#pragma mark - Reload Predictions

- (void)reloadPredictions
{
    if (!self.shouldRefreshPredictions) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(stopPredictionLoaderWillReloadPredictions:)]) {
        [self.delegate stopPredictionLoaderWillReloadPredictions:self];
    }
    [[MITShuttleController sharedController] getPredictionsForStop:self.stop completion:^(NSArray *predictions, NSError *error) {
        if (!error) {
            [self updateNotificationsForPredictions:predictions];
            [self createPredictionsByRoute:predictions];
            if ([self.delegate respondsToSelector:@selector(stopPredictionLoaderDidReloadPredictions:)]) {
                [self.delegate stopPredictionLoaderDidReloadPredictions:self];
            }
        }
    }];
}

- (void)updateNotificationsForPredictions:(NSArray *)predictions
{
    MITShuttleStopNotificationManager *notificationManager = [MITShuttleStopNotificationManager sharedManager];
    for (MITShuttlePredictionList *predictionList in predictions) {
        [notificationManager updateNotificationsForPredictionList:predictionList];
    }
}

- (void)createPredictionsByRoute:(NSArray *)predictions
{
    NSMutableDictionary *newPredictionsByRoute = [NSMutableDictionary dictionary];
    
    for (MITShuttleRoute *route in self.stop.routes) {
        NSMutableArray *predictionsArrayForRoute = [NSMutableArray array];
        
        for (MITShuttlePredictionList *predictionList in predictions) {
            if ([predictionList.routeId isEqualToString:route.identifier] && [predictionList.stopId isEqualToString:self.stop.identifier]) {
                for (MITShuttlePrediction *prediction in predictionList.predictions) {
                    [predictionsArrayForRoute addObject:prediction];
                }
                if (predictionsArrayForRoute.count > 0) {
                    [newPredictionsByRoute setObject:predictionsArrayForRoute forKey:route.identifier];
                }
            }
        }
    }
    
    self.predictionsByRoute = [NSDictionary dictionaryWithDictionary:newPredictionsByRoute];
}

@end
