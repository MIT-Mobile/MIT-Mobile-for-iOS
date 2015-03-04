#import <UIKit/UIKit.h>
#import "MITCalloutView.h"

@class MITMartyResource;
@class MITCalloutMapView;

@interface MITMartyMapViewController : UIViewController
@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) MITCalloutView *calloutView;
@property (nonatomic) UIEdgeInsets mapEdgeInsets;
@property (nonatomic, readonly, weak) MITCalloutMapView *mapView;

- (UIBarButtonItem *)userLocationButton;
- (void)setResources:(NSArray *)resources animated:(BOOL)animated;
- (void)showCalloutForResource:(MITMartyResource *)resource;
- (void)recenterOnVisibleResources:(BOOL)animated;

@end
