#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;
@class MITTiledMapView;

@protocol MITShuttleMapViewControllerDelegate;

typedef NS_ENUM(NSUInteger, MITShuttleMapState) {
    MITShuttleMapStateContracted = 0,
    MITShuttleMapStateContracting,
    MITShuttleMapStateExpanded,
    MITShuttleMapStateExpanding
};

@interface MITShuttleMapViewController : UIViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route;
- (void)setRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop;
- (void)routeUpdated;
- (void)setMapToolBarHidden:(BOOL)hidden;
- (void)centerToShuttleStop:(MITShuttleStop *)stop animated:(BOOL)animated;
- (void)refreshStopAnnotationImagesAnimated:(BOOL)animated;

@property (nonatomic, weak) IBOutlet MITTiledMapView *tiledMapView;
@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;
@property (nonatomic) MITShuttleMapState state;
@property (nonatomic, weak) id<MITShuttleMapViewControllerDelegate> delegate;
@property (nonatomic) BOOL shouldUsePinAnnotations;

@end

@protocol MITShuttleMapViewControllerDelegate <NSObject>

@optional

- (void)shuttleMapViewControllerExitFullscreenButtonPressed:(MITShuttleMapViewController *)mapViewController;
- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didDeselectStop:(MITShuttleStop *)stop;
- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didSelectStop:(MITShuttleStop *)stop;
- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didSelectRoute:(MITShuttleRoute *)route withStop:(MITShuttleStop *)stop;
- (void)shuttleMapViewController:(MITShuttleMapViewController *)mapViewController didClickCalloutForStop:(MITShuttleStop *)stop;

@end
