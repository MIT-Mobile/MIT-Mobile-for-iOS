#import "MITToursStopAnnotation.h"

@interface MITToursStopDirectionAnnotation : MITToursStopAnnotation

@property (nonatomic) BOOL isDestination;
@property (nonatomic) double directionArrowRotationDegrees;

- (instancetype)initWithStop:(MITToursStop *)stop coordinate:(CLLocationCoordinate2D)coordinate isDestination:(BOOL)isDestination;

@end
