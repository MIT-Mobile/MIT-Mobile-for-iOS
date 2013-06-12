
#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleRoute.h"
#import "ShuttleDataManager.h"

@interface RouteMapViewController : UIViewController <MITMapViewDelegate, ShuttleDataManagerDelegate>
@property (nonatomic, retain) ShuttleRoute* route;
@property (nonatomic, retain) ShuttleRoute* routeInfo;

@property (nonatomic, retain) IBOutlet MITMapView* mapView;
@property (nonatomic, retain) IBOutlet UIView* routeInfoView;

@property (nonatomic, retain) MKPolyline * routeLine;
@property (nonatomic, retain) MKPolylineView* routeLineView;

-(IBAction) gpsTouched:(id)sender;
-(IBAction) refreshTouched:(id)sender;

-(void) refreshRouteTitleInfo;

-(void)narrowRegion;
//-(void)assignRoutePoints;
-(void)setRouteOverLayBounds:(CLLocationCoordinate2D)center latDelta:(double)latDelta  lonDelta:(double) lonDelta;

@end
