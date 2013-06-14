#import "MGSCalloutView.h"

#define MAX_CALLOUT_WIDTH (240)

@implementation MGSCalloutView
{
    UIEdgeInsets _borderInsets;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviews];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    
    return self;
}

- (void)initSubviews
{
    _borderInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    
    UILabel *textLabel = [[UILabel alloc] init];
    textLabel.numberOfLines = 0;
    textLabel.backgroundColor = [UIColor clearColor];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    textLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.titleLabel = textLabel;
    [self addSubview:textLabel];
    
    UILabel *detailTextLabel = [[UILabel alloc] init];
    detailTextLabel.numberOfLines = 0;
    detailTextLabel.backgroundColor = [UIColor clearColor];
    detailTextLabel.textColor = [UIColor whiteColor];
    detailTextLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.detailLabel = detailTextLabel;
    [self addSubview:detailTextLabel];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.hidden = YES;
    self.imageView = imageView;
    [self addSubview:imageView];
    
    [self setNeedsLayout];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    if (_accessoryView) {
        [_accessoryView removeFromSuperview];
    }
    
    if (accessoryView) {
        [self addSubview:accessoryView];
    }
    
    _accessoryView = accessoryView;
    [self setNeedsLayout];
}

- (CGRect)bounds
{
    return UIEdgeInsetsInsetRect(self.frame, _borderInsets);
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    CGRect imageFrame = CGRectZero;
    CGRect titleFrame = CGRectZero;
    CGRect detailFrame = CGRectZero;
    CGRect accessoryFrame = self.accessoryView.frame;
    
    if (self.imageView.image) {
        self.imageView.hidden = NO;
        self.imageView.frame = CGRectMake(CGRectGetMinX(bounds), 0, 40, 40);
        self.imageView.center = CGPointMake(self.imageView.center.x,
                                            CGRectGetMidY(bounds));
        imageFrame = self.imageView.frame;
    }
    
    if (self.accessoryView) {
        accessoryFrame.origin.x = CGRectGetMaxX(bounds) - CGRectGetWidth(accessoryFrame);
        self.accessoryView.frame = accessoryFrame;
        self.accessoryView.center = CGPointMake(self.accessoryView.center.x,
                                                CGRectGetMidY(bounds));
        accessoryFrame = self.accessoryView.frame;
    }
    
    if (self.imageView.image) {
        titleFrame.origin = CGPointMake(CGRectGetMaxX(imageFrame) + 10, CGRectGetMinY(bounds));
    } else {
        titleFrame.origin = CGPointMake(CGRectGetMinY(bounds), CGRectGetMinY(bounds));
    }
    
    CGFloat textWidth = CGRectGetMinX(accessoryFrame) - titleFrame.origin.x;
    titleFrame.size = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                                forWidth:textWidth
                                           lineBreakMode:self.titleLabel.lineBreakMode];
    
    detailFrame.origin = CGPointMake(titleFrame.origin.x, CGRectGetMaxY(titleFrame));
    detailFrame.size = [self.detailLabel.text sizeWithFont:self.detailLabel.font
                                                  forWidth:textWidth
                                             lineBreakMode:self.detailLabel.lineBreakMode];
    
    self.titleLabel.frame = titleFrame;
    self.detailLabel.frame = detailFrame;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize calculatedSize = CGSizeZero;
    
    if (self.imageView.image) {
        calculatedSize.width += 40 + 10;
        calculatedSize.height += 40;
    }
    
    if (self.accessoryView) {
        calculatedSize.width += CGRectGetWidth(self.accessoryView.frame);
        calculatedSize.height = MAX(calculatedSize.height,CGRectGetHeight(self.accessoryView.frame));
    }
    
    CGFloat textWidth = MAX_CALLOUT_WIDTH - calculatedSize.width;
    CGSize titleSize = [self.titleLabel.text sizeWithFont:self.titleLabel.font
                                                 forWidth:textWidth
                                            lineBreakMode:self.titleLabel.lineBreakMode];
    
    CGSize detailSize = [self.detailLabel.text sizeWithFont:self.detailLabel.font
                                                  forWidth:textWidth
                                             lineBreakMode:self.detailLabel.lineBreakMode];
    
    textWidth = MIN(textWidth,MAX(titleSize.width,detailSize.width));
    calculatedSize.height = MAX(calculatedSize.height,titleSize.height + detailSize.height);
    
    calculatedSize.width += textWidth + _borderInsets.left + _borderInsets.right;
    calculatedSize.height += _borderInsets.top + _borderInsets.bottom;
    
    return calculatedSize;
}
@end
