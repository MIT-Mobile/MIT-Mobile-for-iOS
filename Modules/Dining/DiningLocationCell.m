#import "DiningLocationCell.h"
#import "UIKit+MITAdditions.h"

@interface DiningLocationCell ()

@property (nonatomic, strong) UILabel * statusLabel;
@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UILabel * subtitleLabel;

@end

@implementation DiningLocationCell

static CGFloat textWidth = 180;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 12)]; // height from font spec
        self.statusLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
        self.statusLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.statusLabel];
        
        self.imageView.frame = CGRectMake(10, 10, 34, 34);
        
        self.titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(54, 10, textWidth, 17)]; // length is calculated, height is for single line of text
        self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.font = [DiningLocationCell fontForPrimaryText];
        [self.contentView addSubview:self.titleLabel];
        
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(54, CGRectGetMaxY(self.titleLabel.frame) + 10, textWidth, 13)];
        self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.subtitleLabel.numberOfLines = 0;
        self.subtitleLabel.font = [DiningLocationCell fontForSecondaryText];
        self.subtitleLabel.textColor = [UIColor colorWithHexString:@"#4c4c4c"];
        [self.contentView addSubview:self.subtitleLabel];
        
    }
    return self;
}

- (UIColor *) textColorForOpenStatus
{
    return (self.statusOpen) ? [UIColor colorWithHexString:@"#008800"] : [UIColor colorWithHexString:@"#bb0000"];
}

- (NSString *) textForOpenStatus
{
    return self.statusOpen ? @"Open" : @"Closed";
}

- (void) adjustSizeForLabel:(UILabel *)label
{
    CGSize maximumLabelSize = CGSizeMake(CGRectGetWidth(label.bounds), CGFLOAT_MAX);
    
    CGSize necessaryLabelSize = [[label text] sizeWithFont:label.font constrainedToSize:maximumLabelSize lineBreakMode:label.lineBreakMode];
    
    CGRect newFrame = label.frame;
    newFrame.size   = CGSizeMake(textWidth, necessaryLabelSize.height);
    label.frame     = newFrame;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.statusLabel.textColor = [self textColorForOpenStatus];
    self.statusLabel.text = [self textForOpenStatus];
    
    [self adjustSizeForLabel:self.titleLabel];
    [self adjustSizeForLabel:self.subtitleLabel];
    
    CGRect imageFrame = CGRectMake(10, 10, 34, 34);
    self.imageView.frame = imageFrame;
    
    CGRect titleFrame = self.titleLabel.frame;
    titleFrame.origin = CGPointMake(CGRectGetMaxX(self.imageView.frame) + 10, 10);
    self.titleLabel.frame = titleFrame;
    
    CGRect frame = self.subtitleLabel.frame;
    frame.origin = CGPointMake(titleFrame.origin.x, CGRectGetMaxY(self.titleLabel.frame) + 10);
    self.subtitleLabel.frame = frame;
    
    self.statusLabel.center = CGPointMake(CGRectGetWidth(self.bounds) - (55), CGRectGetHeight(self.bounds) * 0.5);
}

+ (UIFont *) fontForPrimaryText
{
    return [UIFont fontWithName:@"Helvetica-Bold" size:17];
}

+ (UIFont *) fontForSecondaryText
{
    return [UIFont fontWithName:@"Helvetica" size:13];
}

+ (CGFloat) heightForRowWithTitle:(NSString *)title subtitle:(NSString *) subtitle
{
    CGSize maximumLabelSize = CGSizeMake(textWidth, CGFLOAT_MAX);
    
    CGSize titleLabelSizeThatFits = [title sizeWithFont:[self fontForPrimaryText] constrainedToSize:maximumLabelSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize subtitleLabelSizeThatFits = [subtitle sizeWithFont:[self fontForSecondaryText] constrainedToSize:maximumLabelSize lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = titleLabelSizeThatFits.height + subtitleLabelSizeThatFits.height + (3 * 10); // 30 is padding between text and top and bottom edges
    
    return MAX(54, height);
}

@end
