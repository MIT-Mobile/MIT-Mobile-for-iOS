#import <UIKit/UIKit.h>

@class MITShuttleStop;

@interface MITShuttleStopViewController : UITableViewController

@property (strong, nonatomic) MITShuttleStop *stop;
@property (nonatomic) BOOL shouldRefreshData;

- (instancetype)initWithStop:(MITShuttleStop *)stop;

@end
