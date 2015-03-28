#import <UIKit/UIKit.h>
#import "MITCalloutView.h"

@protocol MITMobiusRoomDataSource;

@class MITMobiusResource;
@class MITCalloutMapView;

@interface MITMobiusMapViewController : UIViewController

@property (nonatomic,weak) id<MITMobiusRoomDataSource> dataSource;
@property (nonatomic, strong) MITCalloutView *calloutView;
@property (nonatomic) UIEdgeInsets mapEdgeInsets;
@property (nonatomic, readonly, weak) MITCalloutMapView *mapView;

- (UIBarButtonItem *)userLocationButton;
- (void)showCalloutForResource:(MITMobiusResource *)resource;
- (void)recenterOnVisibleResources:(BOOL)animated;
- (void)newBuildingsanimated:(BOOL)animated;

@end
