
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
	
	// not sure why we're using two instances of ShuttleRoute
	// or we can get rid of one since changes to ShuttleDataManager 
	// should make both point at the same object
	
	ShuttleRoute* _route;
	
	// extended info for the route. 
	ShuttleRoute* _routeInfo;
	
	NSArray *_vehicleAnnotations;
	
	// extended route info keyed by stop ID
	NSMutableDictionary* _routeStops;
	
	NSTimer* _pollingTimer;
	
	CGFloat _lastZoomLevel;

	UIImage* _smallStopImage;
	UIImage* _smallUpcomingStopImage;
	UIImage* _largeStopImage;
	UIImage* _largeUpcomingStopImage;
	UIViewController* _MITParentViewController;
}

@property (nonatomic, retain) ShuttleRoute* route;
@property (nonatomic, retain) ShuttleRoute* routeInfo;
@property (nonatomic, assign) UIViewController* parentViewController;

@property (readonly) MITMapView* mapView;

-(IBAction) gpsTouched:(id)sender;
-(IBAction) refreshTouched:(id)sender;

-(void) refreshRouteTitleInfo;

@end
