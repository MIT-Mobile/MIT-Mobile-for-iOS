#import <UIKit/UIKit.h>
#import "MITCalloutView.h"

@class MITMartyResource;
@class MITCalloutMapView;

@interface MITMartyMapViewController : UIViewController
@property (nonatomic, strong) MITCalloutView *calloutView;
@property (nonatomic) UIEdgeInsets mapEdgeInsets;
@property (nonatomic, readonly, weak) MITCalloutMapView *mapView;

- (UIBarButtonItem *)userLocationButton;
- (void)showCalloutForResource:(MITMartyResource *)resource;
- (void)recenterOnVisibleResources:(BOOL)animated;
- (void)setBuildingSections:(NSArray *)buildingSections setResourcesByBuilding:(NSDictionary *)resourcesByBuilding animated:(BOOL)animated;

@end
