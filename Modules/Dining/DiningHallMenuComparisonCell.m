#import "DiningHallMenuComparisonCell.h"
#import "UIImage+PDF.h"
#import "UIKit+MITAdditions.h"
#import "DiningDietaryFlag.h"

@interface DiningHallMenuComparisonCell ()

@property (nonatomic, strong) UILabel   * primaryLabel;
@property (nonatomic, strong) UILabel   * secondaryLabel;
@property (nonatomic, strong) UIView    * typeContainer;

@end

#define STANDARD_PADDING 10
#define ICON_SQUARE 12
#define ICON_PADDING 3

@implementation DiningHallMenuComparisonCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        NSInteger labelWidth = CGRectGetWidth(frame) - 27;
        self.primaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(STANDARD_PADDING, STANDARD_PADDING, labelWidth, 10)]; // height is one line of font
        self.primaryLabel.numberOfLines = 0;
        self.primaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.primaryLabel.font = [DiningHallMenuComparisonCell fontForPrimaryLabel];
        
        self.secondaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(STANDARD_PADDING, CGRectGetMaxY(self.primaryLabel.frame), labelWidth, 10)];
        self.secondaryLabel.numberOfLines = 0;
        self.secondaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.secondaryLabel.font = [DiningHallMenuComparisonCell fontForSecondaryLabel];
        
        self.typeContainer = [[UIView alloc] initWithFrame:CGRectMake( CGRectGetWidth(frame) - 22, STANDARD_PADDING, 12, 12)]; // width is from spec, height allows for single dietray type item
        
        self.backgroundView.layer.borderColor = [UIColor darkTextColor].CGColor;
        self.backgroundView.layer.borderWidth = 0.25;
        
        [self.contentView addSubview:self.primaryLabel];
        [self.contentView addSubview:self.secondaryLabel];
        [self.contentView addSubview:self.typeContainer];
        
    }
    return self;
}

+ (UIFont *) fontForPrimaryLabel
{
    return [UIFont fontWithName:@"Helvetica-Bold" size:10];
}

+ (UIFont *) fontForSecondaryLabel
{
    return [UIFont fontWithName:@"Helvetica" size:10];
}


- (CGRect) frameForLabel:(UILabel *)label constrainedToSize:(CGSize) constraint
{
    CGSize necessaryLabelSize = [[label text] sizeWithFont:label.font constrainedToSize:constraint lineBreakMode:label.lineBreakMode];
    
    CGRect newFrame = label.frame;
    newFrame.size   = CGSizeMake(constraint.width, necessaryLabelSize.height);
    return newFrame;
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self.typeContainer removeAllSubviews];
    [self layoutDietaryTypes];
    
    // reclaim the space if there are no dietary types
    CGFloat maxWidth = ([self.typeContainer superview]) ? CGRectGetMinX(self.typeContainer.frame) - 5 : CGRectGetWidth(self.frame);
    
    CGSize constrainingSize = CGSizeMake(maxWidth - (2 * STANDARD_PADDING), CGFLOAT_MAX);
    self.primaryLabel.frame = [self frameForLabel:self.primaryLabel constrainedToSize:constrainingSize];
    
    CGRect secondaryFrame = [self frameForLabel:self.secondaryLabel constrainedToSize:constrainingSize]; // secondary needs to be placed below primary
    self.secondaryLabel.frame = CGRectMake(CGRectGetMinX(secondaryFrame), CGRectGetMaxY(self.primaryLabel.frame), CGRectGetWidth(secondaryFrame), CGRectGetHeight(secondaryFrame));
    
}

- (void) layoutDietaryTypes
{
    if ([self.dietaryTypes count] == 0) {
        [self.typeContainer removeFromSuperview];
        return;
    }
    CGFloat iconSquare  = ICON_SQUARE;
    CGFloat iconPadding = ICON_PADDING;
    CGFloat containerHeight = ([self.dietaryTypes count] * iconSquare) + (([self.dietaryTypes count] - 1) * iconPadding);
    self.typeContainer.frame = CGRectMake(self.typeContainer.frame.origin.x, self.typeContainer.frame.origin.y, iconSquare, containerHeight);
    
    
    CGSize iconSize = CGSizeMake(12, 12);
    int i = 0;
    for (DiningDietaryFlag *type in self.dietaryTypes) {
        UIImage *icon = [UIImage imageWithPDFNamed:type.pdfPath atSize:iconSize];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:icon];
        
        imgView.center = CGPointMake(6, 6 + ((12 + iconPadding) * i));
        i++;
        
        [self.typeContainer addSubview:imgView];
    }
}

+ (CGFloat) heightForComparisonCellOfWidth:(CGFloat)cellWidth withPrimaryText:(NSString *)primary secondaryText:(NSString *)secondary numDietaryTypes:(NSInteger )numDietaryTypes
{
    // checks height of text vs height of dietary types.
    // calculates size of primary and secondary labels and calculates and compares against the required dietary type height
    CGFloat iconHeight = (numDietaryTypes * ICON_SQUARE) + ((numDietaryTypes - 1) * ICON_PADDING);
    
    CGFloat dietaryWidth = STANDARD_PADDING + ICON_SQUARE + 5;
    CGFloat maxWidth = (numDietaryTypes) ? cellWidth - dietaryWidth : cellWidth;
    CGSize constrainingSize = CGSizeMake(maxWidth - (2 * STANDARD_PADDING), CGFLOAT_MAX);
    
    CGSize primarySize = [primary sizeWithFont:[self fontForPrimaryLabel] constrainedToSize:constrainingSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize secondarySize = [secondary sizeWithFont:[self fontForSecondaryLabel] constrainedToSize:constrainingSize lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = MAX(primarySize.height + secondarySize.height, iconHeight);
    
    return height + (2 * STANDARD_PADDING);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
