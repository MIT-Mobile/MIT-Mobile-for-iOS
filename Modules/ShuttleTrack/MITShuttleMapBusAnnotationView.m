#import "MITShuttleMapBusAnnotationView.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicleList.h"

@interface MITShuttleMapBusAnnotationView()

@property (nonatomic, strong) UIImageView *busImageView;

@end

@implementation MITShuttleMapBusAnnotationView

#pragma mark - Init

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.canShowCallout = NO;
        [self setupBusImageView];
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self setupBubbleView];
        }
    }
    return self;
}

#pragma mark - Bus Image View

- (void)setupBusImageView
{
    self.busImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shuttle/bus_annotation"]];
    self.busImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.busImageView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self addSubview:self.busImageView];
}

#pragma mark - Bubble View

- (void)setupBubbleView
{
    MITShuttleVehicle *vehicle = (MITShuttleVehicle *)self.annotation;
    NSString *routeTitle = vehicle.routeTitle;
    if (!routeTitle) {
        return;
    }

    UILabel *routeTitleLabel = [self labelForRouteTitle:routeTitle];
    UIImageView *bubbleImageView = [self bubbleImageView];
    UIView *bubbleContainerView = [self bubbleContainerViewWithFrame:routeTitleLabel.bounds];
    
    [bubbleContainerView addSubview:bubbleImageView];
    [bubbleContainerView addSubview:routeTitleLabel];
    [self addSubview:bubbleContainerView];

    [bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];
    [bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];

    [bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[routeTitleLabel]-14-|" options:0 metrics:nil views:@{@"routeTitleLabel": routeTitleLabel}]];
    [bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[routeTitleLabel]-4-|" options:0 metrics:nil views:@{@"routeTitleLabel": routeTitleLabel}]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bubbleContainerView]-(-10)-[busImageView]" options:0 metrics:nil views:@{@"bubbleContainerView": bubbleContainerView, @"busImageView": self.busImageView}]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.busImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:bubbleContainerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:bubbleContainerView.frame.size.height]];
    
    [self layoutIfNeeded];
    
    self.centerOffset = CGPointMake(-self.busImageView.center.x, -self.busImageView.center.y);
}

- (UILabel *)labelForRouteTitle:(NSString *)routeTitle
{
    UILabel *routeTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    routeTitleLabel.text = routeTitle;
    routeTitleLabel.backgroundColor = [UIColor clearColor];
    routeTitleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    routeTitleLabel.font = [UIFont systemFontOfSize:10.0];
    routeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [routeTitleLabel sizeToFit];
    return routeTitleLabel;
}

- (UIImageView *)bubbleImageView
{
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"shuttle/bus_bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 16, 16)]];
    bubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    return bubbleImageView;
}

- (UIView *)bubbleContainerViewWithFrame:(CGRect)frame
{
    UIView *bubbleContainerView = [[UIView alloc] initWithFrame:frame];
    bubbleContainerView.backgroundColor = [UIColor clearColor];
    bubbleContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    return bubbleContainerView;
}

#pragma mark - Animations

- (void)startAnimating
{
    [self startAnimatingWithAnnotation:self.annotation];
}

- (void)startAnimatingWithAnnotation:(id<MKAnnotation>)annotation
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
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([vehicle.latitude doubleValue], [vehicle.longitude doubleValue]);
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
        CGPoint destinationPoint = [self.mapView convertCoordinate:coordinate toPointToView:self.mapView];
        
        CGFloat heading = [vehicle.heading floatValue] * 2 * M_PI / 360;
        
        if (MKMapRectContainsPoint(self.mapView.visibleMapRect, mapPoint)) {
            if (animated) {
                [UIView animateWithDuration:4.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.busImageView.transform = CGAffineTransformMakeRotation(heading);
                } completion:nil];
                
                [UIView animateWithDuration:8.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.center = destinationPoint;
                } completion:nil];
            } else {
                self.busImageView.transform = CGAffineTransformMakeRotation(heading);
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
