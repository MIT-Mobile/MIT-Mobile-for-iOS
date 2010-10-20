#import <UIKit/UIKit.h>
#import "ShuttleDataManager.h"
#import "RouteInfoTitleCell.h"

@class ShuttleRoute;
@class RouteMapViewController;
@class ShuttleStopCell;
@class ShuttleStopMapAnnotation;

@interface ShuttleRouteViewController : UIViewController <ShuttleDataManagerDelegate, UIAlertViewDelegate> {
    
    ShuttleRoute *_route;
	
	// extended route info, including next stop times. May not include route name or descriptions, 
	// which is why we store it seperately from _route
	ShuttleRoute* _routeInfo;
	
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
}

@property (nonatomic, retain) ShuttleRoute* route;
@property (nonatomic, retain) ShuttleRoute* routeInfo;
@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) RouteMapViewController* routeMapViewController;
@end
