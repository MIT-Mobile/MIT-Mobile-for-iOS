
#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleRoute.h"
#import "ShuttleDataManager.h"

@interface RouteMapViewController : UIViewController <MITMapViewDelegate, ShuttleDataManagerDelegate>
@property (nonatomic, strong) ShuttleRoute* route;
@property (nonatomic, strong) ShuttleRoute* routeInfo;

@property (nonatomic, strong) IBOutlet MITMapView* mapView;
@property (nonatomic, strong) IBOutlet UIView* routeInfoView;

@property (nonatomic, strong) MKPolyline * routeLine;
@property (nonatomic, strong) MKPolylineView* routeLineView;

-(IBAction) gpsTouched:(id)sender;
-(IBAction) refreshTouched:(id)sender;

-(void) refreshRouteTitleInfo;

-(void)narrowRegion;
//-(void)assignRoutePoints;
-(void)setRouteOverLayBounds:(CLLocationCoordinate2D)center latDelta:(double)latDelta  lonDelta:(double) lonDelta;

@end
