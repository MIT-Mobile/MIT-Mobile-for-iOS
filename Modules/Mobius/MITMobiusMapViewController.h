#import <UIKit/UIKit.h>
#import "MITCalloutView.h"

@protocol MITMobiusRootViewRoomDataSource;

@class MITMobiusRoomObject;
@class MITCalloutMapView;

@interface MITMobiusMapViewController : UIViewController

@property (nonatomic,weak) id<MITMobiusRootViewRoomDataSource> dataSource;
@property (nonatomic, strong) MITCalloutView *calloutView;
@property (nonatomic) UIEdgeInsets mapEdgeInsets;
@property (nonatomic, readonly, weak) MITCalloutMapView *mapView;

- (UIBarButtonItem *)userLocationButton;
- (void)showCalloutForRoom:(MITMobiusRoomObject *)room;
- (void)recenterOnVisibleResources:(BOOL)animated;
- (void)reloadMapAnimated:(BOOL)animated;

@end
