#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"
#import "RouteInfoTitleCell.h"
#import "MITModuleURL.h"

@class ShuttleRoute;
@class RouteMapViewController;
@class ShuttleStopCell;
@class ShuttleStopMapAnnotation;

@interface ShuttleRouteViewController : UIViewController <ShuttleDataManagerDelegate, UIAlertViewDelegate>
@property (nonatomic,readonly,strong) MITModuleURL* url;
@property (nonatomic,strong) ShuttleRoute* route;
@property (nonatomic,strong) RouteMapViewController* routeMapViewController;

// used to toggle between map and list view
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated;

// push the view controller for the selected stop (done by the route view controller) because of the large amount of interdependence
// of these two controllers
-(void) pushStopViewControllerWithStop:(ShuttleStop *)stop annotation:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated;

// used to switch to the map view set to a specific stop
-(void) showStop:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated;
@end
