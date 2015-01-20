#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;
@protocol MITShuttleRouteViewControllerDataSource;
@protocol MITShuttleRouteViewControllerDelegate;

@interface MITShuttleRouteViewController : UITableViewController

@property (strong, nonatomic) MITShuttleRoute *route;

@property (weak, nonatomic) id <MITShuttleRouteViewControllerDataSource> dataSource;
@property (weak, nonatomic) id <MITShuttleRouteViewControllerDelegate> delegate;

- (instancetype)initWithRoute:(MITShuttleRoute *)route;
- (void)highlightStop:(MITShuttleStop *)stop;

@end

@protocol MITShuttleRouteViewControllerDataSource <NSObject>

- (BOOL)isMapEmbeddedInRouteViewController:(MITShuttleRouteViewController *)routeViewController;
- (CGFloat)embeddedMapHeightForRouteViewController:(MITShuttleRouteViewController *)routeViewController;

@end

@protocol MITShuttleRouteViewControllerDelegate <NSObject>

- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didSelectStop:(MITShuttleStop *)stop;

@optional
- (void)routeViewController:(MITShuttleRouteViewController *)routeViewController didScrollToContentOffset:(CGPoint)contentOffset;
- (void)routeViewControllerDidRefresh:(MITShuttleRouteViewController *)routeViewController;
- (void)routeViewControllerDidSelectMapPlaceholderCell:(MITShuttleRouteViewController *)routeViewController;

@end
