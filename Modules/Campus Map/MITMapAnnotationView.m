#import <QuartzCore/QuartzCore.h>
#import "MITMapAnnotationView.h"
#import "MITMapView.h"

@implementation MITMapAnnotationView
@synthesize annotation = _annotation;
@synthesize showsCustomCallout = _showsCustomCallout;
@synthesize mapView = _mapView;
@synthesize centeredVertically = _centeredVertically;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
	if (self) {
		self.annotation = annotation;
		self.multipleTouchEnabled = YES;
        self.canShowCallout = NO; // override built-in callout
        self.showsCustomCallout = YES;
	}
	
	return self;
}

- (void)dealloc {
	self.annotation = nil;
	self.mapView = nil;
	
    [super dealloc];
}

@end


#define kPinDropAnimationDuration 1.6

@implementation MITPinAnnotationView

@synthesize shadowView = _shadowView;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.canShowCallout = NO;
        self.backgroundColor = [UIColor clearColor];
        self.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.layer.anchorPoint = CGPointMake(0.5, 1.0);
    }
    return self;
}

- (void)setAnimatesDrop:(BOOL)animatesDrop {
    _animatesDrop = animatesDrop;
    // TODO: separate pin drop from shadow appearing
    if (_animatesDrop) {
        self.image = [UIImage imageNamed:@"map/map_pin_complete.png"];
    } else {
        self.image = [UIImage imageNamed:@"map/map_pin_complete.png"];
    }
}

- (BOOL)animatesDrop {
    return _animatesDrop;
}

- (void)dealloc {
    self.shadowView = nil;
    [super dealloc];
}

@end

