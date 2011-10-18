#import "MITGradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MITGradientView
@dynamic gradientLayer;

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.gradientLayer.colors = [NSArray arrayWithObjects:
                                     (id)[[UIColor colorWithWhite:1.0
                                                            alpha:1.0] CGColor],
                                     (id)[[UIColor colorWithWhite:0.85
                                                            alpha:1.0] CGColor],
                                     nil];
        
        self.gradientLayer.locations = [NSArray arrayWithObjects:
                                        [NSNumber numberWithFloat:0.0],
                                        [NSNumber numberWithFloat:1.0],
                                        nil];
    }
    return self;
}

- (CAGradientLayer*)gradientLayer
{
    return (CAGradientLayer*)[self layer];
}

@end
