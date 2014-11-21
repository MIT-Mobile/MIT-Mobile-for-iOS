#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttleRoute;
@class MITShuttleStopPredictionLoader;

typedef NS_ENUM(NSUInteger, MITShuttleStopViewOption) {
    MITShuttleStopViewOptionAll,
    MITShuttleStopViewOptionIntersectingOnly
};

@interface MITShuttleStopViewController : UITableViewController

@property (strong, nonatomic) MITShuttleStop *stop;
@property (strong, nonatomic) MITShuttleRoute *route;

@property (nonatomic, strong) MITShuttleStopPredictionLoader *predictionLoader;
@property (nonatomic) MITShuttleStopViewOption viewOption;

- (instancetype)initWithStyle:(UITableViewStyle)style stop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route;
- (instancetype)initWithStyle:(UITableViewStyle)style stop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route predictionLoader:(MITShuttleStopPredictionLoader *)predictionLoader;

- (void)beginRefreshing;
- (void)endRefreshing;

@end
