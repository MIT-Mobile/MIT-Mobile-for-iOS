#import "MITToursStopDirectionAnnotation.h"

@implementation MITToursStopDirectionAnnotation

- (instancetype)initWithStop:(MITToursStop *)stop coordinate:(CLLocationCoordinate2D)coordinate isDestination:(BOOL)isDestination
{
    self = [super initWithStop:stop];
    if (self) {
        self.isDestination = isDestination;
        [self setDirectionArrowRotationForCoordinate:coordinate];
    }
    return self;
}

- (void)setDirectionArrowRotationForCoordinate:(CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D firstCoordinate;
    CLLocationCoordinate2D lastCoordinate;
    
    if (self.isDestination) {
        firstCoordinate = coordinate;
        lastCoordinate = self.coordinate;
    }
    else {
        firstCoordinate = self.coordinate;
        lastCoordinate = coordinate;
    }
    
    double heading = [self euclideanHeadingFromCoordinate:firstCoordinate toCoordinate:lastCoordinate];
    
    self.directionArrowRotationDegrees = heading * (M_PI / 180.0);
}

- (double)euclideanHeadingFromCoordinate:(CLLocationCoordinate2D)start toCoordinate:(CLLocationCoordinate2D)end
{
    MKMapPoint startPoint = MKMapPointForCoordinate(start);
    MKMapPoint endPoint = MKMapPointForCoordinate(end);
    
    double deltaX = endPoint.x - startPoint.x;
    double deltaY = endPoint.y - startPoint.y;
    
    return atan2(deltaY, deltaX) * 180 / M_PI;
}

@end
