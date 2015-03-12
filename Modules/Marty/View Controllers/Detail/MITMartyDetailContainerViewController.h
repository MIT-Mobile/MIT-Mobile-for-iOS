#import <UIKit/UIKit.h>
#import "MITToursTour.h"
#import "MITToursStop.h"

@interface MITMartyDetailContainerViewController : UIViewController

@property (nonatomic, strong) MITToursTour *tour;
@property (nonatomic, strong) MITToursStop *currentStop;

- (instancetype)initWithTour:(MITToursTour *)tour stop:(MITToursStop *)stop nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
