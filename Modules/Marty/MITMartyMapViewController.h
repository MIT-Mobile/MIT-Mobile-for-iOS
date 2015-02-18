#import <UIKit/UIKit.h>
#import "SMCalloutView.h"

@class MITMartyResource;

@interface MITMartyMapViewController : UIViewController

@property (nonatomic, strong) NSArray *resources;
@property (nonatomic, strong) SMCalloutView *calloutView;

- (UIBarButtonItem *)userLocationButton;
- (void)resourcesChanged:(BOOL)animated;
- (void)showCalloutForResource:(MITMartyResource *)resource;

@end
