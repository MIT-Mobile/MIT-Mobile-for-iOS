#import <Foundation/Foundation.h>

@class MITShuttleStop;

@protocol MITShuttleStopPredictionLoaderDelegate;

@interface MITShuttleStopPredictionLoader : NSObject

@property (nonatomic, strong) MITShuttleStop *stop;
@property (nonatomic) NSTimeInterval refreshInterval;
@property (nonatomic) BOOL shouldRefreshPredictions;
@property (nonatomic, weak) id <MITShuttleStopPredictionLoaderDelegate> delegate;

- (instancetype)initWithStop:(MITShuttleStop *)stop;
- (NSDictionary *)predictionsByRoute;

- (void)startRefreshingPredictions;
- (void)stopRefreshingPredictions;

@end

@protocol MITShuttleStopPredictionLoaderDelegate <NSObject>

@optional
- (void)stopPredictionLoaderWillReloadPredictions:(MITShuttleStopPredictionLoader *)loader;
- (void)stopPredictionLoaderDidReloadPredictions:(MITShuttleStopPredictionLoader *)loader;

@end
