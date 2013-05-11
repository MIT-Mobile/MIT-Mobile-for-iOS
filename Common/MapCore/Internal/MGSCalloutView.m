
#import "MGSCalloutView.h"
@interface MGSCalloutView ()
@property (nonatomic,weak) UIView *containerView;
@property (nonatomic,weak) UILabel *titleLabel;
@property (nonatomic,weak) UILabel *detailLabel;
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,weak) UIButton *accessoryButton;
@property (nonatomic) CGFloat maximumWidth;

- (void)_init;
@end

@implementation MGSCalloutView
- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _init];
        [self setNeedsLayout];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
        [self setNeedsLayout];
    }
    
    return self;
}

#pragma mark Mutators
- (void)setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
    if (image == nil) {
        [self.imageView removeFromSuperview];
    } else {
        self.imageView.frame = CGRectMake(0,0,48,48);
        [self addSubview:self.imageView];
    }

    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = _title;
    [self setNeedsLayout];
}

- (void)setDetail:(NSString *)detail
{
    _detail = detail;
    self.detailLabel.text = _detail;
    [self setNeedsLayout];
}
#pragma mark -

- (void)_init
{
    // Layout for 160x48, no image
    {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,48,48)];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.autoresizingMask = UIViewAutoresizingNone;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView = imageView;
    }
    
    {
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
            titleLabel.numberOfLines = 0;
            titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            titleLabel.frame = CGRectMake(0, 0, 123, 24);
            titleLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleTopMargin);
            
            [self addSubview:titleLabel];
            self.titleLabel = titleLabel;
        }
        
        {
            UILabel *detailLabel = [[UILabel alloc] init];
            detailLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
            detailLabel.textColor = [UIColor lightGrayColor];
            detailLabel.backgroundColor = [UIColor clearColor];
            detailLabel.numberOfLines = 0;
            detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
            detailLabel.frame = CGRectMake(0, 24, 123, 24);
            detailLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleBottomMargin);
            
            [self addSubview:detailLabel];
            self.detailLabel = detailLabel;
        }
    
    {
        UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        CGRect frame = accessoryButton.frame;
        frame.origin = CGPointMake(131, 9);
        accessoryButton.frame = frame;
        accessoryButton.autoresizingMask = UIViewAutoresizingNone;
        
        [accessoryButton addTarget:self
                            action:@selector(accessoryTouched:)
                  forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:accessoryButton];
        self.accessoryButton = accessoryButton;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    
    CGRect imageFrame = CGRectZero;
    if (self.image) {
        imageFrame.size = CGSizeMake(48.0, 48.0);
        self.imageView.frame = imageFrame;
    } else {
        self.imageView.frame = CGRectZero;
    }
    
    
    CGRect accessoryFrame = self.accessoryButton.frame;
    {
        accessoryFrame.origin = CGPointMake(CGRectGetMaxX(bounds) - CGRectGetWidth(accessoryFrame),
                                            (CGRectGetHeight(bounds) - CGRectGetHeight(accessoryFrame)) / 2.0);
        self.accessoryButton.frame = accessoryFrame;
    }
    
    
    {
        CGFloat originX = CGRectGetMaxX(imageFrame);
        if (self.image) {
            originX += 8.0;
        }
        
        
        CGFloat textWidth = CGRectGetMinX(accessoryFrame) - CGRectGetMaxX(imageFrame) - 8.0;
        CGSize detailTextSize = [self.detail sizeWithFont:self.detailLabel.font
                                        constrainedToSize:CGSizeMake(textWidth,CGRectGetHeight(bounds) / 2.0)
                                            lineBreakMode:self.detailLabel.lineBreakMode];
        
        CGSize titleTextSize = [self.title sizeWithFont:self.titleLabel.font
                                      constrainedToSize:CGSizeMake(textWidth,CGRectGetHeight(bounds) - detailTextSize.height)
                                          lineBreakMode:self.titleLabel.lineBreakMode];
        
        self.titleLabel.frame = CGRectMake(originX, 0, textWidth, titleTextSize.height);
        
        self.detailLabel.frame = CGRectMake(originX,
                                            CGRectGetHeight(bounds) - detailTextSize.height,
                                            textWidth,
                                            detailTextSize.height);
    }
}


- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = CGSizeZero;
    
    if (self.image) {
        CGFloat imageSize = 48.0;
        newSize.width = imageSize + 8.0; // Image: Maximum of 48px square with 8px padding on the right
        newSize.height = imageSize;
    }
    
    newSize.width += 8.0 + CGRectGetWidth(self.accessoryButton.frame); // 8px padding on the left of the accessory button

    CGFloat maxTextWidth = 0.0;
    if (self.superview) {
        maxTextWidth = (CGRectGetWidth(self.superview.bounds) * 0.75) - newSize.width;
    } else {
        // 320px * 0.75
        maxTextWidth = 240 - newSize.width;
    }
    
    CGSize titleSize = [self.title sizeWithFont:self.titleLabel.font
                              constrainedToSize:CGSizeMake(maxTextWidth, CGFLOAT_MAX)
                                  lineBreakMode:self.titleLabel.lineBreakMode];
    
    CGSize detailSize = [self.detail sizeWithFont:self.detailLabel.font
                                constrainedToSize:CGSizeMake(maxTextWidth, CGFLOAT_MAX)
                                    lineBreakMode:self.detailLabel.lineBreakMode];
    CGFloat textHeight = titleSize.height + detailSize.height;
    
    newSize.height = MIN(MAX(newSize.height,textHeight), 48);
    newSize.width += MAX(CGRectGetHeight(self.accessoryButton.frame),MAX(titleSize.width,detailSize.width));
    
    return newSize;
}

- (IBAction)accessoryTouched:(id)sender
{
    if (self.accessoryActionBlock)
    {
        self.accessoryActionBlock(sender);
    }
}
@end
