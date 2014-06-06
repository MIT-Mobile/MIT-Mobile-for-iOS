@class MITShuttleVehicle;

#import <MapKit/MapKit.h>

@interface MITShuttleMapBusAnnotationView : MKAnnotationView

@property (nonatomic, weak) MKMapView *mapView;
@property (nonatomic, strong) NSString *vehicleId;

- (void)updateVehicle:(MITShuttleVehicle *)vehicle animated:(BOOL)animated;
@property (nonatomic, strong) NSNumber *oldlat;
@property (nonatomic, strong) NSNumber *oldlng;

@end
