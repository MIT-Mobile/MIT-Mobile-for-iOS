#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

typedef enum {
    MITShuttleRouteContainerStateRoute = 0,
    MITShuttleRouteContainerStateStop,
    MITShuttleRouteContainerStateMap
} MITShuttleRouteContainerState;

@interface MITShuttleRouteContainerViewController : UIViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop;

@property (nonatomic) MITShuttleRouteContainerState state;

@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;

@end
