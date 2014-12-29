#import <Foundation/Foundation.h>

extern NSString * const kMITShuttlePredictionLoaderWillUpdateNotification;
extern NSString * const kMITShuttlePredictionLoaderDidUpdateNotification;

@class MITShuttleStop;
@class MITShuttleRoute;

@interface MITShuttlePredictionLoader : NSObject

+ (MITShuttlePredictionLoader *)sharedLoader;

- (void)forceRefresh;

- (void)addPredictionDependencyForStop:(MITShuttleStop *)stop;
- (void)removePredictionDependencyForStop:(MITShuttleStop *)stop;

- (void)addPredictionDependencyForRoute:(MITShuttleRoute *)route;
- (void)removePredictionDependencyForRoute:(MITShuttleRoute *)route;

@end
