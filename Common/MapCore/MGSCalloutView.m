#import "MGSCalloutView.h"

static CGFloat const MGSCalloutMaximumWidth = 240.;
static UIEdgeInsets const MGSCalloutContentInsets = {.top = 0, .left = 0., .bottom = 0., .right = 0.};

@implementation MGSCalloutView
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
    imageView.contentMode = UIViewContentModeScaleAspectFit;
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

- (void)layoutSubviews
{
    CGRect insetBounds = UIEdgeInsetsInsetRect(self.bounds, MGSCalloutContentInsets);
    CGRect layoutFrame = insetBounds;

    {
        BOOL hasImage = (self.imageView.image != nil);
        CGRect imageFrame = CGRectZero;
        CGFloat imageWidth = (hasImage ? 40. : 0.);
        CGRectDivide(layoutFrame, &imageFrame, &layoutFrame, imageWidth, CGRectMinXEdge);

        self.imageView.frame = imageFrame;

        if (hasImage) {
            // Add in 8px of horizontal spacing between the image view and its sibling
            layoutFrame.origin.x += 8.;
            layoutFrame.size.width -= 8.;
        }
    }

    {
        CGRect accessoryFrame = CGRectZero;
        CGRectDivide(layoutFrame, &accessoryFrame, &layoutFrame, CGRectGetWidth(self.accessoryView.frame), CGRectMaxXEdge);

        self.accessoryView.frame = accessoryFrame;

        if (self.accessoryView) {
            // Make sure there is at least 8px of horizontal spacing between
            //  the accessory view and its siblings
            layoutFrame.size.width -= 8.;
        }
    }
    
    CGFloat textWidth = CGRectGetWidth(layoutFrame);
    CGSize titleSize = [self.titleLabel sizeThatFits:[self.titleLabel.text sizeWithFont:self.titleLabel.font
                                                                      constrainedToSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                                          lineBreakMode:self.titleLabel.lineBreakMode]];
    CGRect titleLabelFrame = CGRectZero;
    CGRectDivide(layoutFrame, &titleLabelFrame, &layoutFrame, titleSize.height, CGRectMinYEdge);
    self.titleLabel.frame = titleLabelFrame;


    CGSize detailSize = [self.detailLabel sizeThatFits:[self.detailLabel.text sizeWithFont:self.detailLabel.font
                                                                        constrainedToSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                                             lineBreakMode:self.detailLabel.lineBreakMode]];
    // Comparing a float to zero can end very badly. Since
    // sizeThatFits: should be giving us pixel unit sizes,
    // assuming anything less than 0.5 pixels is effectively zero
    //
    // Also, this correction is only made if there is no detail text.
    // If you provide no title but set the detail text, you're on your own.
    if (detailSize.height > 0.5) {
        CGRect detailLabelFrame = CGRectZero;
        CGRectDivide(layoutFrame, &detailLabelFrame, &layoutFrame, detailSize.height, CGRectMaxYEdge);
        self.detailLabel.frame = detailLabelFrame;
    } else {
        CGPoint titleCenter = self.titleLabel.center;
        titleCenter.y = CGRectGetMidY(insetBounds);
        self.titleLabel.center = titleCenter;
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize calculatedSize = CGSizeZero;
    
    if (self.imageView.image) {
        calculatedSize.height = 40.;
        calculatedSize.width = 48.;
    }
    
    if (self.accessoryView) {
        calculatedSize.width += CGRectGetWidth(self.accessoryView.frame) + 8.;
        calculatedSize.height = MAX(calculatedSize.height,CGRectGetHeight(self.accessoryView.frame));
    }
    
    CGFloat textWidth = MGSCalloutMaximumWidth - calculatedSize.width;
    CGSize titleSize = [self.titleLabel sizeThatFits:[self.titleLabel.text sizeWithFont:self.titleLabel.font
                                                                      constrainedToSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                                          lineBreakMode:self.titleLabel.lineBreakMode]];
    
    CGSize detailSize = [self.detailLabel sizeThatFits:[self.detailLabel.text sizeWithFont:self.detailLabel.font
                                                                         constrainedToSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                                             lineBreakMode:self.detailLabel.lineBreakMode]];

    calculatedSize.width += MAX(titleSize.width, detailSize.width);
    calculatedSize.height = MAX(calculatedSize.height,MAX(titleSize.height, detailSize.height));

    calculatedSize.width += MGSCalloutContentInsets.left + MGSCalloutContentInsets.right;
    calculatedSize.height += MGSCalloutContentInsets.top + MGSCalloutContentInsets.bottom;
    
    return calculatedSize;
}
@end
