#import <UIKit/UIKit.h>

@class MITToursStop;

@interface MITToursStopDirectionsViewController : UIViewController

@property (nonatomic, strong) MITToursStop *currentStop;
@property (nonatomic, strong) MITToursStop *nextStop;

@end
