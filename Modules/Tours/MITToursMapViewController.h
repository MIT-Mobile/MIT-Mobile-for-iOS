#import <UIKit/UIKit.h>
#import "MITToursTour.h"

@interface MITToursMapViewController : UIViewController

@property (nonatomic, strong, readonly) MITToursTour *tour;
@property (nonatomic) BOOL shouldShowStopDescriptions;

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (void)centerMapOnUserLocation;

@end
