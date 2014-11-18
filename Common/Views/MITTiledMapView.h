#import <MapKit/MapKit.h>

extern const MKCoordinateRegion kMITShuttleDefaultMapRegion;
extern const MKCoordinateRegion kMITToursDefaultMapRegion;

@protocol MITTiledMapViewButtonDelegate;
@protocol MITTiledMapViewUserTrackingDelegate;

@interface MITTiledMapView : UIView

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, weak) id<MITTiledMapViewButtonDelegate> buttonDelegate;
@property (nonatomic, weak) id<MITTiledMapViewUserTrackingDelegate> userTrackingDelegate;

@property (nonatomic, readonly) BOOL isTrackingUser;

- (void)setMapDelegate:(id<MKMapViewDelegate>) mapDelegate;

- (void)setButtonsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setLeftButtonHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setRightButtonHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)centerMapOnUserLocation;

- (void)showRouteForStops:(NSArray *)stops;
- (void)zoomToFitCoordinates:(NSArray *)coordinates;

- (void)toggleUserTrackingMode;

// protected
- (MKMapView *)createMapView;

@end

@protocol MITTiledMapViewButtonDelegate <NSObject>

- (void)mitTiledMapViewRightButtonPressed:(MITTiledMapView *)mitTiledMapView;

@end

@protocol MITTiledMapViewUserTrackingDelegate <NSObject>

- (void)mitTiledMapView:(MITTiledMapView *)mitTiledMapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated;

@end
