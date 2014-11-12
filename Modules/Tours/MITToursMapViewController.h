#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MITToursTour.h"

@protocol MITToursMapViewControllerDelegate;

@interface MITToursMapViewController : UIViewController

@property (nonatomic, strong, readonly) MITToursTour *tour;
@property (nonatomic) BOOL shouldShowStopDescriptions;

@property (nonatomic, weak) id<MITToursMapViewControllerDelegate> delegate;

@property (nonatomic, readonly) BOOL isTrackingUser;
@property (nonatomic) BOOL shouldShowTourDetailsPanel;

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (void)centerMapOnUserLocation;
- (void)toggleUserTrackingMode;

- (void)selectStop:(MITToursStop *)stop;
- (void)deselectStop:(MITToursStop *)stop;

@end

@protocol MITToursMapViewControllerDelegate <NSObject>

@optional
- (void)mapViewController:(MITToursMapViewController *)mapViewController didSelectStop:(MITToursStop *)stop;
- (void)mapViewController:(MITToursMapViewController *)mapViewController didDeselectStop:(MITToursStop *)stop;
- (void)mapViewController:(MITToursMapViewController *)mapViewController didSelectCalloutForStop:(MITToursStop *)stop;
- (void)mapViewController:(MITToursMapViewController *)mapViewController didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated;
- (void)mapViewControllerDidPressInfoButton:(MITToursMapViewController *)mapViewController;

@end
