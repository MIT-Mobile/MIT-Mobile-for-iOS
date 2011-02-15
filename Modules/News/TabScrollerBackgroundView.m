// To be layered behind the scrolling tab control to give it a transparent background.
// Necessary because UIView only has a backgroundColor property, and -colorWithPatternImage: does not appear to support translucent images.

#import "TabScrollerBackgroundView.h"


@implementation TabScrollerBackgroundView


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        backgroundImage = [[UIImage imageNamed:MITImageNameScrollTabBackgroundTranslucent] retain];
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawTiledImage(context, rect, backgroundImage.CGImage);
}


- (void)dealloc {
    [backgroundImage release];
    [super dealloc];
}


@end
