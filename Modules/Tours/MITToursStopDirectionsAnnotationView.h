#import <MapKit/MapKit.h>

@class MITToursStopDirectionAnnotation;

@interface MITToursStopDirectionsAnnotationView : MKAnnotationView

- (instancetype)initWithStopDirectionAnnotation:(MITToursStopDirectionAnnotation *)stopAnnotation;

@end
