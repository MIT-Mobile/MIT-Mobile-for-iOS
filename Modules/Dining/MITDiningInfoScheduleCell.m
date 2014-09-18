
#import "MITDiningInfoScheduleCell.h"
#import "UIKit+MITAdditions.h"

static CGFloat const kTopBottomOffset = 10.0;
static CGFloat const kLeftOffset = 15.0;

static CGFloat const kTitleLabelWidth = 200;
static CGFloat const kTitleLabelHeight = 20.0;
static CGRect const kTitleLabelBaseRect = {{kLeftOffset, 0}, {kTitleLabelWidth, kTitleLabelHeight}};

static CGFloat const kScheduleLabelsWidth = 100.0;

static CGFloat const kTitleDetailPadding = 6;

@interface MITDiningInfoScheduleCell ()

@end

@implementation MITDiningInfoScheduleCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupTitleLabel];
        [self setupColumns];
    }
    return self;
}

- (void)setupTitleLabel
{
    self.titleLabel = [[UILabel alloc] initWithFrame:kTitleLabelBaseRect];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.font = [self.class titleFont];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.textColor = [UIColor mit_tintColor];
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.titleLabel];
}

- (void)setupColumns
{
    CGRect columnLabelsFrame = CGRectMake(kLeftOffset, 0, kScheduleLabelsWidth, 0);
    self.leftColumnLabel = [[UILabel alloc] initWithFrame:columnLabelsFrame];
    self.leftColumnLabel.backgroundColor = [UIColor clearColor];
    self.leftColumnLabel.numberOfLines = 0;
    self.leftColumnLabel.font = [[self class] detailFont];
    self.leftColumnLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.leftColumnLabel];
    
    self.rightColumnLabel = [[UILabel alloc] initWithFrame:columnLabelsFrame];
    self.rightColumnLabel.backgroundColor = [UIColor clearColor];
    self.rightColumnLabel.numberOfLines = 0;
    self.rightColumnLabel.font = [[self class] detailFont];
    self.rightColumnLabel.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.rightColumnLabel];
}

#pragma mark - Drawing

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self positionTitleLabel];
    [self positionColumns];
}

- (void)positionTitleLabel
{
    CGRect titleLabelFrame = kTitleLabelBaseRect;
    if (self.shouldIncludeTopPadding) {
        titleLabelFrame.origin.y += kTopBottomOffset;
    }
    self.titleLabel.frame = titleLabelFrame;
}

- (void)positionColumns
{
    UIFont *detailFont = [[self class] detailFont];
    
    CGFloat targetScheduleLabelHeight = self.numberOfRowsInEachColumn * detailFont.lineHeight;
    CGFloat targetOriginY = CGRectGetMaxY(self.titleLabel.frame) + kTitleDetailPadding;
    
    CGRect leftColumnFrame = self.leftColumnLabel.frame;
    leftColumnFrame.size.height = targetScheduleLabelHeight;
    leftColumnFrame.origin.y = targetOriginY;
    self.leftColumnLabel.frame = leftColumnFrame;
    
    CGRect rightColumnFrame = self.rightColumnLabel.frame;
    rightColumnFrame.size.height = targetScheduleLabelHeight;
    rightColumnFrame.origin.y = targetOriginY;
    rightColumnFrame.origin.x = CGRectGetMaxX(leftColumnFrame) + kLeftOffset;
    rightColumnFrame.size.width = CGRectGetWidth(self.bounds) - rightColumnFrame.origin.x;
    self.rightColumnLabel.frame = rightColumnFrame;
}

#pragma mark - Class Methods

+ (CGFloat)heightForCellWithNumberOfRowsInEachColumn:(NSInteger)numberOfRows withTopPadding:(BOOL)includeTopBuffer
{
    CGFloat height = 0;
    CGFloat topOffset = includeTopBuffer ? kTopBottomOffset : 0;
    height = topOffset + CGRectGetHeight(kTitleLabelBaseRect) + kTitleDetailPadding + ([self detailFont].lineHeight * numberOfRows) + kTopBottomOffset;
    return height > 44 ? height : 44;
}

+ (UIFont *)titleFont {
    return [UIFont systemFontOfSize:15.0];
}

+ (UIFont *)detailFont {
    return [UIFont systemFontOfSize:17.0];
}

#pragma mark - Getters | Setters

- (void)setShouldIncludeTopPadding:(BOOL)shouldIncludeTopPadding
{
    if (_shouldIncludeTopPadding != shouldIncludeTopPadding) {
        _shouldIncludeTopPadding = shouldIncludeTopPadding;
        [self setNeedsLayout];
    }
}

@end
