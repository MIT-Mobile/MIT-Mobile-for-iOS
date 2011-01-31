#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"
#import "RouteInfoTitleCell.h"
#import "MITModuleURL.h"

@class ShuttleRoute;
@class RouteMapViewController;
@class ShuttleStopCell;
@class ShuttleStopMapAnnotation;

@interface ShuttleRouteViewController : UIViewController <ShuttleDataManagerDelegate, UIAlertViewDelegate> {
    
    ShuttleRoute *_route;
	
	// extended route info, including next stop times. May not include route name or descriptions, 
	// which is why we store it seperately from _route
	//ShuttleRoute* _routeInfo;
	
	UIBarButtonItem* _viewTypeButton;
	
	IBOutlet UITableView* _tableView;
	
	IBOutlet RouteInfoTitleCell* _titleCell;
	
	IBOutlet UITableViewCell* _loadingCell;
	
	IBOutlet ShuttleStopCell* _shuttleStopCell;
	
	// for when the user switches to a map of the listed route. 
	RouteMapViewController* _routeMapViewController;
	BOOL _mapShowing;
	
	BOOL _routeLoaded;
	BOOL _shownError;
	
	UIImage* _smallStopImage;
	UIImage* _smallUpcomingStopImage;
	NSTimer* _pollingTimer;
	
	ShuttleStopMapAnnotation* _selectedStopAnnotation;
	
	MITModuleURL* url;
}

// used to toggle between map and list view
-(void) setMapViewMode:(BOOL)showMap animated:(BOOL)animated;

// push the view controller for the selected stop (done by the route view controller) because of the large amount of interdependence
// of these two controllers
-(void) pushStopViewControllerWithStop:(ShuttleStop *)stop annotation:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated;

// used to switch to the map view set to a specific stop
-(void) showStop:(ShuttleStopMapAnnotation *)annotation animated:(BOOL)animated;

@property (readonly) MITModuleURL* url;
@property (nonatomic, retain) ShuttleRoute* route;
//@property (nonatomic, retain) ShuttleRoute* routeInfo;
@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) RouteMapViewController* routeMapViewController;

@end
