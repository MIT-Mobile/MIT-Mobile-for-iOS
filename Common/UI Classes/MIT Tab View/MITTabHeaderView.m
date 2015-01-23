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
        self.imageView = [[[UIImageView alloc] init] autorelease];
        [self addSubview:self.imageView];
        
        UIImage *image = [UIImage imageNamed:MITImageTabViewHeader];
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
