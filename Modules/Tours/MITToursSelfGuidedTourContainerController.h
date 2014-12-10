#import <UIKit/UIKit.h>

@class MITToursTour;

@interface MITToursSelfGuidedTourContainerController : UIViewController

- (instancetype)initWithTour:(MITToursTour *)tour;

@property (nonatomic, strong) MITToursTour *selfGuidedTour;

@end
