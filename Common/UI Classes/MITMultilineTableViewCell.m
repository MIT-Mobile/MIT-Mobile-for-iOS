#import "MITMultilineTableViewCell.h"
#import "MITUIConstants.h"

@interface MITMultilineTableViewCell ()
@property UIEdgeInsets contentInsets;
@property (nonatomic,weak) UILabel *headlineLabel;
@property (nonatomic,weak) UILabel *bodyLabel;
@end

@implementation MITMultilineTableViewCell
- (id)init
{
    self = [super init];
    if (self) {
        self.contentInsets = UIEdgeInsetsMake(4, 10, 4, 4);
        self.contentView.autoresizesSubviews = YES;
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentInsets = UIEdgeInsetsMake(4, 10, 4, 8);
        self.contentView.autoresizesSubviews = YES;
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)prepareForReuse
{
    [self.headlineLabel removeFromSuperview];
    [self.bodyLabel removeFromSuperview];
}

#pragma mark - Lazy Views
- (UILabel*)headlineLabel
{
    if (!_headlineLabel) {
        UILabel *headlineLabel = [[UILabel alloc] init];
        headlineLabel.backgroundColor = [UIColor clearColor];
        headlineLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        headlineLabel.textColor = CELL_STANDARD_FONT_COLOR;
        headlineLabel.highlightedTextColor = [UIColor whiteColor];
        headlineLabel.numberOfLines = 0;
        headlineLabel.lineBreakMode = NSLineBreakByWordWrapping;
        headlineLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:headlineLabel];
        self.headlineLabel = headlineLabel;
    }

    return _headlineLabel;
}

- (UILabel*)bodyLabel
{
    if (!_bodyLabel) {
        UILabel *bodyLabel = [[UILabel alloc] init];
        bodyLabel.backgroundColor = [UIColor clearColor];
        bodyLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
        bodyLabel.textColor = CELL_DETAIL_FONT_COLOR;
        bodyLabel.highlightedTextColor = [UIColor whiteColor];
        bodyLabel.numberOfLines = 0;
        bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:bodyLabel];
        self.bodyLabel = bodyLabel;
    }
    
    return _bodyLabel;
}

- (void)updateConstraints
{
    [super updateConstraints];

    CGFloat contentViewWidth = CGRectGetWidth(self.contentView.bounds);
    self.headlineLabel.preferredMaxLayoutWidth = contentViewWidth;
    self.bodyLabel.preferredMaxLayoutWidth = contentViewWidth;

    NSDictionary *constraintViews = @{@"headlineLabel" : self.headlineLabel,
                                      @"bodyLabel" : self.bodyLabel};
    NSDictionary *constraintMetrics = @{@"top" : @(self.contentInsets.top),
                                        @"left" : @(self.contentInsets.left),
                                        @"bottom" : @(self.contentInsets.bottom),
                                        @"right" : @(self.contentInsets.right)};

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[headlineLabel(>=0@250)]-(right@500)-|"
                                                                             options:0
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[bodyLabel(>=0@250)]-(right@500)-|"
                                                                             options:0
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top)-[headlineLabel][bodyLabel]-(>=bottom@250)-|"
                                                                             options:NSLayoutFormatAlignAllLeft
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (CGSize)sizeThatFits:(CGSize)size
{
    // TODO: Make sure that checking the accessory view here is kosher.
    CGFloat textWidth = size.width - self.contentInsets.left - self.contentInsets.right;

    if (self.accessoryType != UITableViewCellAccessoryNone) {
        textWidth -= 20.; // *should* work for most cases (increase if needed). Worst case scenario, we should
                          // overestimate and end up with a bit more whitespace.
    } else if (self.accessoryView) {
        textWidth -= CGRectGetWidth(self.accessoryView.frame);
    }

    NSString *headlineText = self.headlineLabel.text;
    CGSize headlineTextSize = [headlineText sizeWithFont:self.headlineLabel.font
                                                  constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                                      lineBreakMode:self.headlineLabel.lineBreakMode];
    CGSize headlineLabelSize = [self.headlineLabel sizeThatFits:headlineTextSize];


    NSString *bodyText = self.bodyLabel.text;
    CGSize bodyLabelSize = [self.bodyLabel sizeThatFits:[bodyText sizeWithFont:self.bodyLabel.font
                                                             constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                                                 lineBreakMode:self.bodyLabel.lineBreakMode]];
    
    size.height = headlineLabelSize.height + bodyLabelSize.height + self.contentInsets.top + self.contentInsets.bottom;
    return size;
}

@end
