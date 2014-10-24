#import <UIKit/UIKit.h>
#import "MITToursTour.h"

@interface MITToursMapViewController : UIViewController

@property (nonatomic, strong, readonly) MITToursTour *tour;

- (instancetype)initWithTour:(MITToursTour *)tour nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
