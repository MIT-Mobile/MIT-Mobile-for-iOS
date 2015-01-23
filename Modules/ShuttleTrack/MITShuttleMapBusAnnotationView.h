@class MITShuttleVehicle;

#import <MapKit/MapKit.h>

@interface MITShuttleMapBusAnnotationView : MKAnnotationView

@property (nonatomic, weak) MKMapView *mapView;

- (void)updateViewAnimated:(BOOL)animated;
- (void)stopAnimating;
- (void)setRouteTitle:(NSString *)routeTitle;

@end
