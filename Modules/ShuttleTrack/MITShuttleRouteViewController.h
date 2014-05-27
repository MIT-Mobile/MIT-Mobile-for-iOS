#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;
@protocol MITShuttleRouteViewControllerDelegate;

@interface MITShuttleRouteViewController : UITableViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route;

@property (strong, nonatomic) MITShuttleRoute *route;
@property (weak, nonatomic) id <MITShuttleRouteViewControllerDelegate> delegate;

@end

@protocol MITShuttleRouteViewControllerDelegate <NSObject>

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didSelectStop:(MITShuttleStop *)stop;

@end
