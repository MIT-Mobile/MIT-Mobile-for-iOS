#import <UIKit/UIKit.h>
#import "MITCalloutView.h"

@class MITMobiusResource;
@class MITCalloutMapView;

@interface MITMobiusMapViewController : UIViewController
@property (nonatomic, strong) MITCalloutView *calloutView;
@property (nonatomic) UIEdgeInsets mapEdgeInsets;
@property (nonatomic, readonly, weak) MITCalloutMapView *mapView;

- (UIBarButtonItem *)userLocationButton;
- (void)showCalloutForResource:(MITMobiusResource *)resource;
- (void)recenterOnVisibleResources:(BOOL)animated;
- (void)setBuildingSections:(NSArray *)buildingSections setResourcesByBuilding:(NSDictionary *)resourcesByBuilding animated:(BOOL)animated;

@end
