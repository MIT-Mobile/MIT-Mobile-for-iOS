#import <MapKit/MapKit.h>

extern const MKCoordinateRegion kMITShuttleDefaultMapRegion;
extern const MKCoordinateRegion kMITToursDefaultMapRegion;

@protocol MITTiledMapViewButtonDelegate;

@interface MITTiledMapView : UIView

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, weak) id<MITTiledMapViewButtonDelegate> buttonDelegate;

- (void)setMapDelegate:(id<MKMapViewDelegate>) mapDelegate;

- (void)setButtonsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setLeftButtonHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setRightButtonHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)centerMapOnUserLocation;

- (void)showRouteForStops:(NSArray *)stops;

// protected
- (MKMapView *)createMapView;

@end

@protocol MITTiledMapViewButtonDelegate <NSObject>

- (void)mitTiledMapViewRightButtonPressed:(MITTiledMapView *)mitTiledMapView;

@end