#import "MITShuttlePredictionLoader.h"
#import "MITShuttleStop.h"
#import "MITShuttleRoute.h"
#import "MITShuttleController.h"

NSString * const kMITShuttlePredictionLoaderWillUpdateNotification = @"kMITShuttlePredictionLoaderWillUpdateNotification";
NSString * const kMITShuttlePredictionLoaderDidUpdateNotification = @"kMITShuttlePredictionLoaderDidUpdateNotification";

@interface MITShuttlePredictionLoader ()

@property (nonatomic, strong) NSMutableDictionary *stopDependencyTuplesByAgency;
@property (strong, nonatomic) NSTimer *predictionsRefreshTimer;

@end

@implementation MITShuttlePredictionLoader

+ (MITShuttlePredictionLoader *)sharedLoader
{
    static MITShuttlePredictionLoader *sharedLoader;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLoader = [[MITShuttlePredictionLoader alloc] init];
    });
    
    return sharedLoader;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        self.stopDependencyTuplesByAgency = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc
{
    [self stopTimer];
}

- (void)startTimerIfNeeded
{
    if (!self.predictionsRefreshTimer) {
        NSTimer *predictionsRefreshTimer = [NSTimer timerWithTimeInterval:10.0
                                                                     target:self
                                                                   selector:@selector(refreshPredictions)
                                                                   userInfo:nil
                                                                    repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:predictionsRefreshTimer forMode:NSRunLoopCommonModes];
        self.predictionsRefreshTimer = predictionsRefreshTimer;
    }
}

- (void)stopTimer
{
    [self.predictionsRefreshTimer invalidate];
    self.predictionsRefreshTimer = nil;
}

- (void)forceRefresh
{
    [self refreshPredictions];
}

#pragma mark - Making API Calls

- (void)refreshPredictions
{
    @synchronized(self) {
        if (self.stopDependencyTuplesByAgency.allKeys.count < 1) {
            [self stopTimer];
            return;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMITShuttlePredictionLoaderWillUpdateNotification object:nil];
        MITShuttlePredictionsRequestData *requestData = [[MITShuttlePredictionsRequestData alloc] init];
                
        for (NSString *agency in [self.stopDependencyTuplesByAgency allKeys]) {
            for (NSString *tuple in [[self.stopDependencyTuplesByAgency objectForKey:agency] allKeys]) {
                [requestData addTuple:tuple forAgency:agency];
            }
        }
        
        [[MITShuttleController sharedController] getPredictionsForPredictionsRequestData:requestData completion:^(NSArray *predictionLists, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kMITShuttlePredictionLoaderDidUpdateNotification object:nil];
        }];
    }
}

#pragma mark - Managing Stop Dependencies

- (void)incrementDependencyInternal:(MITShuttleStop *)stop
{
    NSString *agency = stop.route.agency;
    NSString *idTuple = stop.stopAndRouteIdTuple;
    
    NSMutableDictionary *agencyDictionary = [self.stopDependencyTuplesByAgency objectForKey:agency];
    if (!agencyDictionary) {
        agencyDictionary = [NSMutableDictionary dictionary];
        [self.stopDependencyTuplesByAgency setObject:agencyDictionary forKey:agency];
    }
    
    NSNumber *numberOfDependencies = [agencyDictionary objectForKey:idTuple];
    NSInteger newNumber = [numberOfDependencies integerValue] + 1;
    [agencyDictionary setObject:@(newNumber) forKey:idTuple];
}

- (void)decrementDependencyInternal:(MITShuttleStop *)stop
{
    NSString *agency = stop.route.agency;
    NSString *idTuple = stop.stopAndRouteIdTuple;
    
    NSMutableDictionary *agencyDictionary = [self.stopDependencyTuplesByAgency objectForKey:agency];
    if (agencyDictionary) {
        NSNumber *numberOfDependencies = [agencyDictionary objectForKey:idTuple];
        if ([numberOfDependencies integerValue] > 1) {
            NSInteger newNumber = [numberOfDependencies integerValue] - 1;
            [agencyDictionary setObject:@(newNumber) forKey:idTuple];
        } else {
            [agencyDictionary removeObjectForKey:idTuple];
            if (agencyDictionary.allKeys.count < 1) {
                [self.stopDependencyTuplesByAgency removeObjectForKey:agency];
            }
        }
    }
}

- (void)addPredictionDependencyForStop:(MITShuttleStop *)stop
{
    @synchronized(self) {
        [self incrementDependencyInternal:stop];
        [self startTimerIfNeeded];
    }
}

- (void)removePredictionDependencyForStop:(MITShuttleStop *)stop
{
    @synchronized(self) {
        [self decrementDependencyInternal:stop];
    }
}

- (void)addPredictionDependencyForStops:(NSArray *)stops
{
    @synchronized(self) {
        for (MITShuttleStop *stop in stops) {
            [self incrementDependencyInternal:stop];
        }
        [self startTimerIfNeeded];
    }
}

- (void)removePredictionDependencyForStops:(NSArray *)stops
{
    @synchronized(self) {
        for (MITShuttleStop *stop in stops) {
            [self decrementDependencyInternal:stop];
        }
    }
}

- (void)addPredictionDependencyForRoute:(MITShuttleRoute *)route
{
    for (MITShuttleStop *stop in route.stops) {
        [self addPredictionDependencyForStop:stop];
    }
}

- (void)removePredictionDependencyForRoute:(MITShuttleRoute *)route
{
    for (MITShuttleStop *stop in route.stops) {
        [self removePredictionDependencyForStop:stop];
    }
}

@end
