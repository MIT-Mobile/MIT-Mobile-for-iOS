
#import "MGSCalloutView.h"
@interface MGSCalloutView ()
@property (nonatomic,weak) UILabel *titleLabel;
@property (nonatomic,weak) UILabel *detailLabel;
@property (nonatomic,weak) UIImageView *imageView;
@property (nonatomic,assign) CGSize imageSize;
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
        titleLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = UILineBreakModeWordWrap;
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
        detailLabel.lineBreakMode = UILineBreakModeWordWrap;
        detailLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                       UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleRightMargin);
        
        [self addSubview:detailLabel];
        self.detailLabel = detailLabel;
    }
    
    [self setNeedsLayout];
}


- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
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

}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGFloat width = size.width - (CGRectGetMaxX(self.imageView.bounds) + 10);
    
    if (width <= 0)
    {
        width = [[UIScreen mainScreen] applicationFrame].size.width * 0.65;
    }
    
    if (self.imageView.image)
    {
        width -= CGRectGetWidth(self.imageView.bounds) + 10;
    }
    
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                        constrainedToSize:CGSizeMake(width,
                                                                     CGFLOAT_MAX)
                                            lineBreakMode:self.titleLabel.lineBreakMode];
    
    CGSize detailSize = [self.detailLabel.text sizeWithFont:self.detailLabel.font
                                          constrainedToSize:CGSizeMake(width,
                                                                     CGFLOAT_MAX)
                                              lineBreakMode:self.detailLabel.lineBreakMode];
    
    CGSize newSize = CGSizeMake(MIN(width, MAX(titleSize.width, detailSize.width)),0);
    
    if (self.imageView.image)
    {
        newSize.height = MAX(CGRectGetHeight(self.imageView.bounds), titleSize.height + detailSize.height);
    }
    else
    {
        newSize.height = titleSize.height + detailSize.height;
    }
    
    return newSize;
}
@end
