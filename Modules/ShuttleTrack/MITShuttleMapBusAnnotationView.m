#import "MITShuttleMapBusAnnotationView.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicleList.h"

@interface MITShuttleMapBusAnnotationView()

@property (nonatomic, strong) UIView *bubbleContainerView;
@property (nonatomic, strong) UILabel *routeTitleLabel;
@property (nonatomic, strong) CALayer *busImageLayer;
@property (nonatomic, strong) CALayer *bubbleLayer;

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
    self.busImageLayer = [[CALayer alloc] init];
    UIImage *busImage = [UIImage imageNamed:MITImageShuttlesAnnotationBus];
    self.busImageLayer.bounds = CGRectMake(0, 0, busImage.size.width, busImage.size.height);
    self.busImageLayer.contents = (__bridge id)busImage.CGImage;
    [self.layer addSublayer:self.busImageLayer];
}

#pragma mark - Bubble View

- (void)setupBubbleView
{
    MITShuttleVehicle *vehicle = (MITShuttleVehicle *)self.annotation;
    NSString *routeTitle = vehicle.route.title;
    if (!routeTitle) {
        return;
    }

    self.routeTitleLabel = [self labelForRouteTitle:routeTitle];
    
    self.bubbleContainerView = [self bubbleContainerViewWithFrame:self.routeTitleLabel.bounds];
    CGRect bubbleContainerFrame = self.bubbleContainerView.frame;
    bubbleContainerFrame.size.width += 21; // Padding for title, 6 on left, 15 on right
    bubbleContainerFrame.size.height += 6; // Padding for title, 1 on top, 5 on bottom
    if (bubbleContainerFrame.size.height < 24) {
        bubbleContainerFrame.size.height = 24;
    }
    self.bubbleContainerView.frame = bubbleContainerFrame;
    
    
    UIImageView *bubbleImageView = [self bubbleImageView];
    
    [self.bubbleContainerView addSubview:bubbleImageView];
    [self.bubbleContainerView addSubview:self.routeTitleLabel];
    
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];
    
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[routeTitleLabel]-15-|" options:0 metrics:nil views:@{@"routeTitleLabel": self.routeTitleLabel}]];
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[routeTitleLabel]-5-|" options:0 metrics:nil views:@{@"routeTitleLabel": self.routeTitleLabel}]];
    
    [self.bubbleContainerView setNeedsLayout];
    [self.bubbleContainerView layoutIfNeeded];
    
    UIGraphicsBeginImageContextWithOptions(self.bubbleContainerView.bounds.size, NO, 0.0);
    [self.bubbleContainerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *bubbleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.bubbleLayer = [[CALayer alloc] init];
    self.bubbleLayer.bounds = CGRectMake(0, 0, bubbleImage.size.width, bubbleImage.size.height);
    self.bubbleLayer.contents = (__bridge id)bubbleImage.CGImage;
    self.bubbleLayer.position = CGPointMake(-((self.bubbleLayer.bounds.size.width / 2) + 8), -(self.bubbleLayer.bounds.size.height / 2));
    
    [self.layer addSublayer:self.bubbleLayer];
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
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:MITImageShuttlesBusBubble] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 14, 16)]];
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

#pragma mark - Route Title

- (void)setRouteTitle:(NSString *)routeTitle
{
    self.routeTitleLabel.text = routeTitle;
    [self.routeTitleLabel sizeToFit];
    [self layoutIfNeeded];
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
                    self.busImageLayer.affineTransform = CGAffineTransformMakeRotation(heading);
                } completion:nil];
                
                [UIView animateWithDuration:8.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.center = destinationPoint;
                } completion:nil];
            } else {
                self.busImageLayer.affineTransform = CGAffineTransformMakeRotation(heading);
                self.center = destinationPoint;
            }
        }
    }
}

- (void)cleanup
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.layer removeAllAnimations];
    [self.busImageLayer removeAllAnimations];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self cleanup];
}

@end
