#import "MITMultilineTableViewCell.h"
#import "MITUIConstants.h"

@interface MITMultilineTableViewCell ()
@property (nonatomic,weak) UILabel *headlineLabel;
@property (nonatomic,weak) UILabel *bodyLabel;
@end

@implementation MITMultilineTableViewCell
- (id)init
{
    self = [super init];
    if (self) {
        _contentInset = UIEdgeInsetsMake(10, 10, 10, 8);
        self.contentView.layer.masksToBounds = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _contentInset = UIEdgeInsetsMake(10, 10, 10, 8);
        self.contentView.layer.masksToBounds = YES;
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
        headlineLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight |
                                          UIViewAutoresizingFlexibleBottomMargin);
        headlineLabel.backgroundColor = [UIColor clearColor];
        headlineLabel.font = [UIFont boldSystemFontOfSize:CELL_STANDARD_FONT_SIZE];
        headlineLabel.textColor = CELL_STANDARD_FONT_COLOR;
        headlineLabel.highlightedTextColor = [UIColor whiteColor];
        headlineLabel.numberOfLines = 0;
        headlineLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:headlineLabel];
        self.headlineLabel = headlineLabel;
        [self setNeedsLayout];
    }
    return _headlineLabel;
}

- (UILabel*)bodyLabel
{
    if (!_bodyLabel) {
        UILabel *bodyLabel = [[UILabel alloc] init];
        bodyLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);
        bodyLabel.backgroundColor = [UIColor clearColor];
        bodyLabel.font = [UIFont systemFontOfSize:CELL_DETAIL_FONT_SIZE];
        bodyLabel.textColor = CELL_DETAIL_FONT_COLOR;
        bodyLabel.highlightedTextColor = [UIColor whiteColor];
        bodyLabel.numberOfLines = 0;
        bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:bodyLabel];
        self.bodyLabel = bodyLabel;
        [self setNeedsLayout];
    }
    
    return _bodyLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = UIEdgeInsetsInsetRect(self.contentView.bounds,self.contentInset);
    
    CGSize headlineSize = [self.headlineLabel sizeThatFits:bounds.size];
    self.headlineLabel.frame = CGRectMake(CGRectGetMinX(bounds),
                                          CGRectGetMinY(bounds),
                                          CGRectGetWidth(bounds),
                                          headlineSize.height);
    
    CGSize bodySize = [self.bodyLabel sizeThatFits:bounds.size];
    self.bodyLabel.frame = CGRectMake(CGRectGetMinX(bounds),
                                      CGRectGetMaxY(self.headlineLabel.frame),
                                      CGRectGetWidth(bounds),
                                      bodySize.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (CGSize)sizeThatFits:(CGSize)size
{
    // Make sure everything is layed out before we start asking things
    // about their frames.
    [self layoutIfNeeded];
    
    CGFloat textWidth = size.width - fabs(self.contentView.frame.size.width - self.bounds.size.width);
    textWidth -= self.contentInset.top + self.contentInset.bottom;
    
    CGSize headlineSize = [self.headlineLabel.text sizeWithFont:self.headlineLabel.font
                                              constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                                  lineBreakMode:self.headlineLabel.lineBreakMode];
    
    CGSize bodySize = [self.bodyLabel.text sizeWithFont:self.bodyLabel.font
                                      constrainedToSize:CGSizeMake(textWidth,CGFLOAT_MAX)
                                          lineBreakMode:self.bodyLabel.lineBreakMode];
    
    size.height = headlineSize.height + bodySize.height + self.contentInset.top + self.contentInset.bottom;
    return size;
}

@end
