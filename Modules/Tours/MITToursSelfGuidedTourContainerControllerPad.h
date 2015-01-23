#import <UIKit/UIKit.h>

@class MITToursTour;

@interface MITToursSelfGuidedTourContainerControllerPad : UIViewController

- (instancetype)initWithTour:(MITToursTour *)tour;

@property (nonatomic, strong) MITToursTour *selfGuidedTour;

@end
