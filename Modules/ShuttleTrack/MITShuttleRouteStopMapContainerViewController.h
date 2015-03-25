#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

@interface MITShuttleRouteStopMapContainerViewController : UIViewController

@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;


- (instancetype)initWithRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop;

@end
