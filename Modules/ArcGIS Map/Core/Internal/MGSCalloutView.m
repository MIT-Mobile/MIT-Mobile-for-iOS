
#import "MGSCalloutView.h"
@interface MGSCalloutView ()
@property (nonatomic,weak) UILabel *titleLabel;
@property (nonatomic,weak) UILabel *detailLabel;
@property (nonatomic,weak) UIImageView *imageView;
@property (nonatomic,weak) UIButton *accessoryButton;
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
        self.imageSize = CGSizeMake(64.0, 64.0);
        
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.autoresizingMask = UIViewAutoresizingNone;
        
        [self addSubview:imageView];
        self.imageView = imageView;
    }
    
    {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleRightMargin);
        
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
        detailLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleRightMargin);
        
        [self addSubview:detailLabel];
        self.detailLabel = detailLabel;
    }
    
    {
        UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [accessoryButton addTarget:self
                            action:@selector(accessoryTouched:)
                  forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:accessoryButton];
        self.accessoryButton = accessoryButton;
    }
    
    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
    bounds.size.width -= CGRectGetWidth(self.accessoryButton.frame) + 10;
    
    if (self.imageView.image)
    {
        self.imageView.frame = CGRectMake(CGRectGetMinX(bounds) + 10,
                                           ((CGRectGetHeight(bounds) - CGRectGetMinY(bounds)) - self.imageSize.height) / 2.0,
                                           self.imageSize.width,
                                           self.imageSize.height);
        
        bounds.origin.x += CGRectGetMaxX(self.imageView.frame) + 10;
    }

    {
        CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                            constrainedToSize:CGSizeMake(CGRectGetWidth(bounds) - CGRectGetMinX(bounds),
                                                                         CGRectGetHeight(bounds) - CGRectGetMinY(bounds))
                                                lineBreakMode:self.titleLabel.lineBreakMode];
        
        CGRect titleRect = CGRectMake(CGRectGetMinX(bounds),
                                      CGRectGetMinY(bounds),
                                      titleSize.width,
                                      titleSize.height);
        
        self.titleLabel.frame = titleRect;
        bounds.origin.y += CGRectGetHeight(titleRect);
    }
    
    if ([self.detailLabel.text length])
    {
        CGSize detailSize = [self.detailLabel.text sizeWithFont:self.detailLabel.font
                                             constrainedToSize:CGSizeMake(CGRectGetWidth(bounds) - CGRectGetMinX(bounds),
                                                                          CGRectGetHeight(bounds) - CGRectGetMinY(bounds))
                                                 lineBreakMode:self.detailLabel.lineBreakMode];
        
        CGRect detailRect = CGRectMake(CGRectGetMinX(bounds),
                                      CGRectGetMinY(bounds),
                                      detailSize.width,
                                      detailSize.height);
        
        self.detailLabel.frame = detailRect;
    }
    
    CGRect buttonFrame = self.accessoryButton.frame;
    buttonFrame.origin.x = bounds.size.width + 10;
    buttonFrame.origin.y = ((CGRectGetHeight(self.bounds) - CGRectGetMinY(self.bounds)) - CGRectGetHeight(self.accessoryButton.frame)) / 2.0;
    
    self.accessoryButton.frame = buttonFrame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat otherWidth = CGRectGetWidth(self.accessoryButton.frame) + 10;
    if (self.imageView.image)
    {
        otherWidth += CGRectGetMaxX(self.imageView.frame) + 10;
    }
    
    CGFloat width = size.width - otherWidth;
    
    if (width <= 64.0)
    {
        width = ([[UIScreen mainScreen] applicationFrame].size.width * 0.75) - otherWidth;
    }
    
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                        constrainedToSize:CGSizeMake(width,
                                                                     CGFLOAT_MAX)
                                            lineBreakMode:self.titleLabel.lineBreakMode];
    
    CGSize detailSize = [self.detailLabel.text sizeWithFont:self.detailLabel.font
                                          constrainedToSize:CGSizeMake(width,
                                                                     CGFLOAT_MAX)
                                              lineBreakMode:self.detailLabel.lineBreakMode];
    
    CGFloat textWidth = MAX(titleSize.width, detailSize.width);
    CGFloat newHeight = 0;
    CGFloat imageHeight = 0;
    if (self.imageView.image)
    {
        imageHeight = CGRectGetHeight(self.imageView.frame);
    }
    
    newHeight = MAX(imageHeight,
                    MAX(CGRectGetHeight(self.accessoryButton.frame),
                        titleSize.height + detailSize.height));
    
    CGSize newSize = CGSizeMake(MIN(width,textWidth) + otherWidth,newHeight);
    
    return newSize;
}

- (IBAction)accessoryTouched:(id)sender
{
    if (self.accessoryBlock)
    {
        self.accessoryBlock(sender);
    }
}
@end
