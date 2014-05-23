#import <UIKit/UIKit.h>

@class MITShuttleRoute;

@interface MITShuttleRouteViewController : UITableViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route;

@property (strong, nonatomic) MITShuttleRoute *route;

@end
