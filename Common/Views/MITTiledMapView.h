#import <MapKit/MapKit.h>

extern const MKCoordinateRegion kMITShuttleDefaultMapRegion;

@protocol MITTiledMapViewButtonDelegate;

@interface MITTiledMapView : UIView

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, weak) id<MITTiledMapViewButtonDelegate> buttonDelegate;

- (void)setButtonsHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setLeftButtonHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setRightButtonHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)centerMapOnUserLocation;

@end

@protocol MITTiledMapViewButtonDelegate <NSObject>

- (void)mitTiledMapViewRightButtonPressed:(MITTiledMapView *)mitTiledMapView;

@end