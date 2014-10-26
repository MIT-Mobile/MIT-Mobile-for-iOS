#import "MITDiningHallMenuComparisonCell.h"
#import "UIImage+PDF.h"
#import "UIKit+MITAdditions.h"
#import "MITDiningMenuItem.h"
//#import "DiningDietaryFlag.h"

@interface ComparisonBackgroundView : UIView

@end

@implementation ComparisonBackgroundView

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextAddRect(ctx, rect);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillPath(ctx);
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:0.88 alpha:1.0].CGColor);
    CGFloat borderWidth = 1.0;
    CGContextSetLineWidth(ctx, borderWidth);
    CGContextMoveToPoint(ctx, 0, rect.size.height - borderWidth);
    CGContextAddLineToPoint(ctx, rect.size.width, rect.size.height - borderWidth);
    CGContextStrokePath(ctx);
}

@end

#pragma mark - DiningHallMenuComparisonCell

@interface MITDiningHallMenuComparisonCell ()

@property (nonatomic, strong) UILabel *primaryLabel;
@property (nonatomic, strong) UILabel *secondaryLabel;
@property (nonatomic, strong) UIView *typeContainer;

@end

#define STANDARD_PADDING 10
#define ICON_SQUARE 16
#define ICON_PADDING 4

@implementation MITDiningHallMenuComparisonCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        NSInteger labelWidth = CGRectGetWidth(frame) - 27;
        self.primaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(STANDARD_PADDING, STANDARD_PADDING, labelWidth, 10)]; // height is one line of font
        self.primaryLabel.numberOfLines = 0;
        self.primaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.primaryLabel.font = [MITDiningHallMenuComparisonCell fontForPrimaryLabel];
        
        self.secondaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(STANDARD_PADDING, CGRectGetMaxY(self.primaryLabel.frame), labelWidth, 10)];
        self.secondaryLabel.numberOfLines = 0;
        self.secondaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.secondaryLabel.font = [MITDiningHallMenuComparisonCell fontForSecondaryLabel];
        
        self.typeContainer = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame) - (STANDARD_PADDING + ICON_SQUARE), STANDARD_PADDING, ICON_SQUARE, ICON_SQUARE)]; // width is from spec, height allows for single dietary type item
        // custom backgroundView to draw divider
        ComparisonBackgroundView *backView = [[ComparisonBackgroundView alloc] initWithFrame:frame];
        self.backgroundView = backView;
        
        [self.contentView addSubview:self.primaryLabel];
        [self.contentView addSubview:self.secondaryLabel];
        [self.contentView addSubview:self.typeContainer];
        
    }
    return self;
}

- (void)setDietaryTypes:(NSArray *)dietaryTypes
{
    _dietaryTypes = dietaryTypes;
    [self setNeedsLayout];
}

- (void)prepareForReuse
{
    self.primaryLabel.text = @"";
    self.secondaryLabel.text = @"";
    self.dietaryTypes = nil;
    [self.typeContainer removeAllSubviews];
    
    ComparisonBackgroundView *backView = [[ComparisonBackgroundView alloc] initWithFrame:self.frame];   // need to reallocate backgroundView so it doesn't draw over itself and thicken border line
    self.backgroundView = backView;
}

+ (UIFont *) fontForPrimaryLabel
{
    return [UIFont boldSystemFontOfSize:12];
}

+ (UIFont *) fontForSecondaryLabel
{
    return [UIFont systemFontOfSize:12];
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

    [self layoutDietaryTypes];
    
    // reclaim the space if there are no dietary types
    CGFloat maxWidth = ([self.dietaryTypes count] > 0) ? CGRectGetMinX(self.typeContainer.frame) + 5 : CGRectGetWidth(self.frame);
    
    CGSize constrainingSize = CGSizeMake(maxWidth - (2 * STANDARD_PADDING), CGFLOAT_MAX);
    self.primaryLabel.frame = [self frameForLabel:self.primaryLabel constrainedToSize:constrainingSize];
    
    CGRect secondaryFrame = [self frameForLabel:self.secondaryLabel constrainedToSize:constrainingSize]; // secondary needs to be placed below primary
    self.secondaryLabel.frame = CGRectMake(CGRectGetMinX(secondaryFrame), CGRectGetMaxY(self.primaryLabel.frame), CGRectGetWidth(secondaryFrame), CGRectGetHeight(secondaryFrame));
    
}

- (void)layoutDietaryTypes
{
    if ((!self.dietaryTypes || [self.dietaryTypes count] == 0) && [self.typeContainer subviews]) {
        [self.typeContainer removeAllSubviews];
        return;
    }
    CGFloat iconSquare  = ICON_SQUARE;
    CGFloat iconPadding = ICON_PADDING;
    CGFloat containerHeight = ([self.dietaryTypes count] * iconSquare) + (([self.dietaryTypes count] - 1) * iconPadding);
    self.typeContainer.frame = CGRectMake(self.typeContainer.frame.origin.x, self.typeContainer.frame.origin.y, iconSquare, containerHeight);
    
    
    CGSize iconSize = CGSizeMake(ICON_SQUARE, ICON_SQUARE);
    int flagIndexOffset = 0;
    for (NSString *flag in self.dietaryTypes) {
        UIImage *icon = [UIImage imageWithPDFNamed:[MITDiningMenuItem pdfNameForDietaryFlag:flag] atSize:iconSize];
        UIImageView *imgView = [[UIImageView alloc] initWithImage:icon];
        
        imgView.center = CGPointMake(ICON_SQUARE / 2.0, (ICON_SQUARE / 2.0) + ((ICON_SQUARE + iconPadding) * flagIndexOffset));
        flagIndexOffset++;
        
        [self.typeContainer addSubview:imgView];
    }
}

+ (CGFloat) heightForComparisonCellOfWidth:(CGFloat)cellWidth withPrimaryText:(NSString *)primary secondaryText:(NSString *)secondary numDietaryTypes:(NSInteger )numDietaryTypes
{
    // checks height of text vs height of dietary types.
    // calculates size of primary and secondary labels and calculates and compares against the required dietary type height
    CGFloat iconHeight = (numDietaryTypes * ICON_SQUARE) + ((numDietaryTypes - 1) * ICON_PADDING);
    
    CGFloat dietaryWidth = ICON_SQUARE + 5;
    CGFloat maxWidth = (numDietaryTypes) ? cellWidth - dietaryWidth : cellWidth;
    CGSize constrainingSize = CGSizeMake(maxWidth - (2 * STANDARD_PADDING), CGFLOAT_MAX);
    
    CGSize primarySize = [primary sizeWithFont:[self fontForPrimaryLabel] constrainedToSize:constrainingSize lineBreakMode:NSLineBreakByWordWrapping];
    CGSize secondarySize = [secondary sizeWithFont:[self fontForSecondaryLabel] constrainedToSize:constrainingSize lineBreakMode:NSLineBreakByWordWrapping];
    
    CGFloat height = MAX(primarySize.height + secondarySize.height, iconHeight);
    
    return height + (2 * STANDARD_PADDING);
}

@end
