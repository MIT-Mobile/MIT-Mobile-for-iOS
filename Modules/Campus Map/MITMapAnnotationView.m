#import <QuartzCore/QuartzCore.h>
#import "MITMapAnnotationView.h"
#import "MITMapView.h"

@implementation MITMapAnnotationView
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

@end


#define kPinDropAnimationDuration 1.6

@implementation MITPinAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.canShowCallout = NO;
        self.backgroundColor = [UIColor clearColor];
        self.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.image = [UIImage imageNamed:MITImageMapAnnotationPin];
        self.centerOffset = CGPointMake(0, -(self.image.size.height / 2.0));
        self.calloutOffset = CGPointMake(0, (self.image.size.height / 4.0));
        self.canShowCallout = YES;
    }
    return self;
}

- (void)setAnimatesDrop:(BOOL)animatesDrop {
    _animatesDrop = animatesDrop;
    
    // TODO: separate pin drop from shadow appearing
    if (_animatesDrop) {
        self.image = [UIImage imageNamed:MITImageMapAnnotationPin];
    } else {
        self.image = [UIImage imageNamed:MITImageMapAnnotationPin];
    }
}

@end

