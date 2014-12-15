#import <MapKit/MapKit.h>

extern const MKCoordinateRegion kMITShuttleDefaultMapRegion;
extern const MKCoordinateRegion kMITToursDefaultMapRegion;

@class MITCalloutMapView;
@protocol MITTiledMapViewUserTrackingDelegate;

@interface MITTiledMapView : UIView

@property (nonatomic, strong) MITCalloutMapView *mapView;
@property (nonatomic, readonly) UIBarButtonItem *userLocationButton;

@property (nonatomic, weak) id<MITTiledMapViewUserTrackingDelegate> userTrackingDelegate;

@property (nonatomic, readonly) BOOL isTrackingUser;

- (void)setMapDelegate:(id<MKMapViewDelegate>) mapDelegate;

- (void)showRouteForStops:(NSArray *)stops;
- (void)zoomToFitCoordinates:(NSArray *)coordinates;

// protected
- (MITCalloutMapView *)createMapView;

@end

@protocol MITTiledMapViewUserTrackingDelegate <NSObject>

- (void)mitTiledMapView:(MITTiledMapView *)mitTiledMapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated;

@end
