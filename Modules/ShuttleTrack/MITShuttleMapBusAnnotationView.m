#import "MITShuttleMapBusAnnotationView.h"
#import "MITShuttleVehicle.h"

@implementation MITShuttleMapBusAnnotationView

#pragma mark - Init

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.image = [UIImage imageNamed:@"shuttle/shuttle"];
        self.canShowCallout = NO;
    }
    return self;
}

#pragma mark - Animations

- (void)startAnimating
{
    [self startAnimatingWithAnnotation:self.annotation];
}

- (void)startAnimatingWithAnnotation:(MITShuttleVehicle *)annotation
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMoveAnnotation:) name:kMITShuttleVehicleCoordinateUpdatedNotification object:annotation];
}

- (void)stopAnimating
{
    [self cleanup];
}

- (void)setAnnotation:(id <MKAnnotation>)anAnnotation
{
    if (anAnnotation) {
        if (anAnnotation != self.annotation) {
            [self startAnimatingWithAnnotation:anAnnotation];
        }
    } else {
        [self cleanup];
    }
    
    [super setAnnotation:anAnnotation];
    
    if (self.mapView && anAnnotation) {
        [self updateVehicle:(MITShuttleVehicle *)anAnnotation animated:NO];
    }
}

- (void)didMoveAnnotation:(NSNotification *)notification
{
    [self updateVehicle:[notification object] animated:YES];
}

- (void)updateVehicle:(MITShuttleVehicle *)vehicle animated:(BOOL)animated
{
    [self.superview bringSubviewToFront:self];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([vehicle.latitude doubleValue], [vehicle.longitude doubleValue]);
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
        CGPoint destinationPoint = [self.mapView convertCoordinate:coordinate toPointToView:self.mapView];
        
        CGFloat heading = [vehicle.heading floatValue] * 2 * M_PI / 360;
        
        if (MKMapRectContainsPoint(self.mapView.visibleMapRect, mapPoint)) {
            if (animated) {
                [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.transform = CGAffineTransformMakeRotation(heading);
                } completion:nil];
                
                [UIView animateWithDuration:3.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.center = destinationPoint;
                } completion:nil];
            } else {
                self.transform = CGAffineTransformMakeRotation(heading);
                self.center = destinationPoint;
            }
        }
    }
}

- (void)cleanup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.layer removeAllAnimations];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self cleanup];
}

@end
