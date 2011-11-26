#import "MITTabHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@interface MITTabHeaderView ()
@property (nonatomic,retain) UIImageView *imageView;
@end

@implementation MITTabHeaderView
@synthesize imageView = _imageView;
@dynamic gradientLayer;
@dynamic backgroundImage;

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
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
        
        self.imageView = [[[UIImageView alloc] init] autorelease];
        [self addSubview:self.imageView];
        
        UIImage *image = [UIImage imageNamed:@"global/tab2-header"];
        self.backgroundImage = [image stretchableImageWithLeftCapWidth:1 topCapHeight:1];
    }
    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.frame = self.bounds;
}

- (CAGradientLayer*)gradientLayer
{
    return (CAGradientLayer*)[self layer];
}

- (void)setBackgroundImage:(UIImage*)image
{
    self.imageView.image = image;
}

- (UIImage*)backgroundImage
{
    return self.imageView.image;
}

@end
