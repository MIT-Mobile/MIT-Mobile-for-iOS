#import <UIKit/UIKit.h>

@class MITShuttleStop;

@interface MITShuttleStopViewController : UITableViewController

- (instancetype)initWithStop:(MITShuttleStop *)stop;

@property (strong, nonatomic) MITShuttleStop *stop;

@end
