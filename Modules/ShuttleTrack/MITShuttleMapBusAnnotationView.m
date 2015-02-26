#import "MITShuttleMapBusAnnotationView.h"
#import "MITShuttleVehicle.h"
#import "MITShuttleRoute.h"
#import "MITShuttleVehicleList.h"
#import "UIKit+MITShuttles.h"

@interface MITShuttleMapBusAnnotationView()

@property (nonatomic, strong) UIView *bubbleContainerView;
@property (nonatomic, strong) UILabel *routeTitleLabel;
@property (nonatomic, strong) CALayer *busImageLayer;
@property (nonatomic, strong) CALayer *bubbleLayer;
@property (nonatomic, readonly) MITShuttleVehicle *vehicle;

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
            [self setupBubble];
            
            MITShuttleVehicle *vehicle = (MITShuttleVehicle *)annotation;
            NSString *routeTitle = vehicle.route.title;
            
            if (routeTitle) {
                [self refreshBubbleWithRouteTitle:routeTitle];
            }
        }
    }
    return self;
}

- (void)setAnnotation:(id <MKAnnotation>)anAnnotation
{
    if (!anAnnotation) {
        [self cleanup];
    } else {
        NSAssert([anAnnotation isKindOfClass:[MITShuttleVehicle class]], @"Annotations for MITShuttleMapButAnnotationView must be of class MITShuttleVehicle");
    }
    
    [super setAnnotation:anAnnotation];
    
    if (self.mapView && anAnnotation) {
        [self updateViewAnimated:NO];
    }
}

- (MITShuttleVehicle *)vehicle
{
    return (MITShuttleVehicle *)self.annotation;
}

#pragma mark - Setup

- (void)setupBusImageView
{
    self.busImageLayer = [[CALayer alloc] init];
    UIImage *busImage = [UIImage imageNamed:MITImageShuttlesAnnotationBus];
    self.busImageLayer.bounds = CGRectMake(0, 0, busImage.size.width, busImage.size.height);
    self.busImageLayer.contents = (__bridge id)busImage.CGImage;
    [self.layer addSublayer:self.busImageLayer];
}

- (void)setupBubble
{
    [self setupRouteTitleLabel];
    [self setupBubbleContainerView];
    [self setupBubbleLayer];
}

- (void)setupBubbleLayer
{
    self.bubbleLayer = [[CALayer alloc] init];
}

- (void)setupRouteTitleLabel
{
    self.routeTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.routeTitleLabel.backgroundColor = [UIColor clearColor];
    self.routeTitleLabel.textColor = [UIColor mit_busAnnotationTitleTextColor];
    self.routeTitleLabel.font = [UIFont mit_busAnnotationTitleFont];
    self.routeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
}

- (void)setupBubbleContainerView
{
    self.bubbleContainerView = [[UIView alloc] init];
    self.bubbleContainerView.backgroundColor = [UIColor clearColor];
    self.bubbleContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView *bubbleImageView = [self bubbleImageView];
    
    [self.bubbleContainerView addSubview:bubbleImageView];
    [self.bubbleContainerView addSubview:self.routeTitleLabel];
    
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bubbleImageView]|" options:0 metrics:nil views:@{@"bubbleImageView": bubbleImageView}]];
    
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[routeTitleLabel]-15-|" options:0 metrics:nil views:@{@"routeTitleLabel": self.routeTitleLabel}]];
    [self.bubbleContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[routeTitleLabel]-5-|" options:0 metrics:nil views:@{@"routeTitleLabel": self.routeTitleLabel}]];
}

- (UIImageView *)bubbleImageView
{
    UIImageView *bubbleImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:MITImageShuttlesBusBubble] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 14, 16)]];
    bubbleImageView.translatesAutoresizingMaskIntoConstraints = NO;
    return bubbleImageView;
}

#pragma mark - Bubble Refresh

- (void)refreshBubbleWithRouteTitle:(NSString *)routeTitle
{
    [self refreshRouteTitleLabelWithRouteTitle:routeTitle];
    [self refreshBubbleContainerView];
    [self refreshBubbleLayer];
}

- (void)refreshRouteTitleLabelWithRouteTitle:(NSString *)routeTitle
{
    self.routeTitleLabel.text = routeTitle;
    [self.routeTitleLabel sizeToFit];
}

- (void)refreshBubbleContainerView
{
    CGRect bubbleContainerBounds = CGRectMake(0, 0, self.routeTitleLabel.bounds.size.width, self.routeTitleLabel.bounds.size.height);
    bubbleContainerBounds.size.width += 21; // Padding for title, 6 on left, 15 on right
    bubbleContainerBounds.size.height += 6; // Padding for title, 1 on top, 5 on bottom
    if (bubbleContainerBounds.size.height < 24) {
        bubbleContainerBounds.size.height = 24;
    }
    
    self.bubbleContainerView.bounds = bubbleContainerBounds;
    
    [self.bubbleContainerView setNeedsLayout];
    [self.bubbleContainerView layoutIfNeeded];
}

- (void)refreshBubbleLayer
{
    [self.bubbleLayer removeFromSuperlayer];
    
    UIGraphicsBeginImageContextWithOptions(self.bubbleContainerView.bounds.size, NO, 0.0);
    [self.bubbleContainerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *bubbleImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.bubbleLayer.bounds = CGRectMake(0, 0, bubbleImage.size.width, bubbleImage.size.height);
    self.bubbleLayer.contents = (__bridge id)bubbleImage.CGImage;
    self.bubbleLayer.position = CGPointMake(-((self.bubbleLayer.bounds.size.width / 2) + 8), -(self.bubbleLayer.bounds.size.height / 2));
    
    [self.layer addSublayer:self.bubbleLayer];
}

#pragma mark - Route Title

- (void)setRouteTitle:(NSString *)routeTitle
{
    if ([routeTitle isEqualToString:self.routeTitleLabel.text]) {
        return;
    }
    [self refreshBubbleWithRouteTitle:routeTitle];
}

#pragma mark - Animations

- (void)updateViewAnimated:(BOOL)animated
{
    CLLocationCoordinate2D coordinate = self.annotation.coordinate;
    
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        MKMapPoint mapPoint = MKMapPointForCoordinate(coordinate);
        CGPoint destinationPoint = [self.mapView convertCoordinate:coordinate toPointToView:self.mapView];
        
        CGFloat rawVehicleHeading = self.vehicle.heading;
        
        // Convert mapHeading to 360 degree scale.
        CGFloat mapHeading = self.mapView.camera.heading;
        if (mapHeading < 0) {
            mapHeading = fabs(mapHeading);
        } else if (mapHeading > 0) {
            mapHeading = 360 - mapHeading;
        }
        
        CGFloat offsetHeading = (rawVehicleHeading + mapHeading);
        while (offsetHeading > 360.0) {
            offsetHeading -= 360.0;
        }
        
        CGFloat headingInRadians = offsetHeading * M_PI / 180;
        if (MKMapRectContainsPoint(self.mapView.visibleMapRect, mapPoint)) {
            if (animated) {
                [UIView animateWithDuration:4.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.busImageLayer.affineTransform = CGAffineTransformMakeRotation(headingInRadians);
                } completion:nil];
                
                [UIView animateWithDuration:8.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.center = destinationPoint;
                } completion:nil];
            } else {
                self.busImageLayer.affineTransform = CGAffineTransformMakeRotation(headingInRadians);
                self.center = destinationPoint;
            }
        }
    }
}

- (void)stopAnimating
{
    [self cleanup];
}

- (void)cleanup
{
    [self.layer removeAllAnimations];
    [self.busImageLayer removeAllAnimations];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [self cleanup];
}

@end
