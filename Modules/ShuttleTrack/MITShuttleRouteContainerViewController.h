#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

typedef NS_ENUM(NSUInteger, MITShuttleRouteContainerState) {
    MITShuttleRouteContainerStateRoute = 0,
    MITShuttleRouteContainerStateStop,
    MITShuttleRouteContainerStateMap
};

@interface MITShuttleRouteContainerViewController : UIViewController <UIScrollViewDelegate>

- (instancetype)initWithRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop;

@property (nonatomic) MITShuttleRouteContainerState state;

@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;

@end
