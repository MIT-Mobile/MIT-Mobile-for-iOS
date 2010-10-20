
#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleRoute.h"
#import "ShuttleDataManager.h"

@interface RouteMapViewController : UIViewController <MITMapViewDelegate, ShuttleDataManagerDelegate>{

	IBOutlet MITMapView* _mapView;
	
	IBOutlet UILabel* _routeTitleLabel;
	IBOutlet UILabel* _routeStatusLabel;
	IBOutlet UIButton* _gpsButton; 
	IBOutlet UIImageView *_scrim;
	
	ShuttleRoute* _route;
	
	// extended info for the route. 
	ShuttleRoute* _routeInfo;
	
	// extended route info keyed by stop ID
	NSMutableDictionary* _routeStops;
	
	NSTimer* _pollingTimer;
	
	CGFloat _lastZoomLevel;

	UIImage* _smallStopImage;
	UIImage* _smallUpcomingStopImage;
	UIImage* _largeStopImage;
	UIImage* _largeUpcomingStopImage;
	
	UINavigationController* _parentsNavController;
}

@property (nonatomic, retain) ShuttleRoute* route;
@property (nonatomic, retain) ShuttleRoute* routeInfo;
@property (nonatomic, assign) UINavigationController* parentsNavController;

@property (readonly) MITMapView* mapView;

-(IBAction) gpsTouched:(id)sender;
-(IBAction) refreshTouched:(id)sender;

@end
