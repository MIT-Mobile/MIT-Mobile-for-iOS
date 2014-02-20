#import <QuartzCore/QuartzCore.h>
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
        self.contentInsets = [[self class] defaultContentInsets];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentInsets = [[self class] defaultContentInsets];
    }
    return self;
}

- (void)prepareForReuse
{
    [self.headlineLabel removeFromSuperview];
    [self.bodyLabel removeFromSuperview];
}

+ (UIEdgeInsets)defaultContentInsets
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        return UIEdgeInsetsMake(8, 15, 8, 10);
    } else {
        return UIEdgeInsetsMake(8, 10, 8, 10);
    }
}

#pragma mark - Lazy Views
- (UILabel*)headlineLabel
{
    if (!_headlineLabel) {
        UILabel *headlineLabel = [[UILabel alloc] init];
        headlineLabel.backgroundColor = [UIColor clearColor];
        headlineLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        headlineLabel.textColor = [UIColor blackColor];
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            headlineLabel.highlightedTextColor = [UIColor whiteColor];
        }
        headlineLabel.numberOfLines = 0;
        headlineLabel.lineBreakMode = NSLineBreakByWordWrapping;
        headlineLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:headlineLabel];
        [self.contentView setNeedsUpdateConstraints];

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
        bodyLabel.textColor = [UIColor darkGrayColor];
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            bodyLabel.highlightedTextColor = [UIColor whiteColor];
        }
        bodyLabel.numberOfLines = 0;
        bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:bodyLabel];
        [self.contentView setNeedsUpdateConstraints];

        self.bodyLabel = bodyLabel;
    }
    
    return _bodyLabel;
}

- (void)updateConstraints
{
    [super updateConstraints];

    CGFloat preferredTextWidth = CGRectGetWidth(self.contentView.bounds) - self.contentInsets.left - self.contentInsets.right;
    if (self.accessoryType != UITableViewCellAccessoryNone) {
        preferredTextWidth -= 30.;
    }
    self.headlineLabel.preferredMaxLayoutWidth = preferredTextWidth;
    self.bodyLabel.preferredMaxLayoutWidth = preferredTextWidth;

    NSDictionary *constraintViews = @{@"headlineLabel" : self.headlineLabel,
                                      @"bodyLabel" : self.bodyLabel};
    NSDictionary *constraintMetrics = @{@"top" : @(self.contentInsets.top),
                                        @"left" : @(self.contentInsets.left),
                                        @"bottom" : @(self.contentInsets.bottom),
                                        @"right" : @(self.contentInsets.right)};

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-left-[headlineLabel]-(>=right@250)-|"
                                                                             options:0
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-left-[bodyLabel]-(>=right@250)-|"
                                                                             options:0
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];

    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[headlineLabel(>=0)][bodyLabel(>=0)]"
                                                                             options:0
                                                                             metrics:constraintMetrics
                                                                               views:constraintViews]];
    [self.contentView exerciseAmbiguityInLayout];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (CGSize)sizeThatFits:(CGSize)size
{
    // TODO: Make sure that checking the accessory view here is kosher.
    [self layoutIfNeeded];

    CGFloat textWidth = MIN(CGRectGetWidth(self.contentView.bounds), size.width) - self.contentInsets.left - self.contentInsets.right;
    if (self.accessoryType != UITableViewCellAccessoryNone && NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        textWidth -= 30.;
    }

    NSString *headlineText = self.headlineLabel.text;
    CGSize headlineLabelSize = [self.headlineLabel sizeThatFits:[headlineText sizeWithFont:self.headlineLabel.font
                                                                         constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                                                             lineBreakMode:self.headlineLabel.lineBreakMode]];


    NSString *bodyText = self.bodyLabel.text;
    CGSize bodyLabelSize = [self.bodyLabel sizeThatFits:[bodyText sizeWithFont:self.bodyLabel.font
                                                             constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                                                 lineBreakMode:self.bodyLabel.lineBreakMode]];
    
    size.height = headlineLabelSize.height + bodyLabelSize.height + self.contentInsets.top + self.contentInsets.bottom;
    return size;
}

@end
