@class MITShuttleVehicle;

#import <MapKit/MapKit.h>

@interface MITShuttleMapBusAnnotationView : MKAnnotationView

@property (nonatomic, weak) MKMapView *mapView;

- (void)startAnimating;
- (void)stopAnimating;
- (void)setRouteTitle:(NSString *)routeTitle;

@end
