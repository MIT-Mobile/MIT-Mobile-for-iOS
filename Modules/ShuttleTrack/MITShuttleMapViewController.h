#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

@protocol MITShuttleMapViewControllerDelegate;

typedef enum {
    MITShuttleMapStateContracted = 0,
    MITShuttleMapStateExpanded
} MITShuttleMapState;

@interface MITShuttleMapViewController : UIViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route;

@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;
@property (nonatomic) MITShuttleMapState state;
@property (nonatomic, weak) id<MITShuttleMapViewControllerDelegate> delegate;

@end

@protocol MITShuttleMapViewControllerDelegate <NSObject>

- (void)shuttleMapViewControllerExitFullscreenButtonPressed:(MITShuttleMapViewController *)mapViewController;

@end