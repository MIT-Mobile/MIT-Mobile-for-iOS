#import "MITDiningHallMealCollectionCell.h"
#import "MITDiningMenuItem.h"
#import "Foundation+MITAdditions.h"
#import "UIImage+PDF.h"
#import "MITDiningDietaryFlagListViewController.h"

@interface MITDiningHallMealCollectionCell () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *stationLabel;
@property (nonatomic, weak) IBOutlet UITextView *mealTitleTextView;
@property (nonatomic, weak) IBOutlet UILabel *mealDescriptionLabel;
@property (nonatomic, strong) UIPopoverController *dietaryFlagPopoverController;

@end

@implementation MITDiningHallMealCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.stationLabel.preferredMaxLayoutWidth = self.bounds.size.width;
    self.mealDescriptionLabel.preferredMaxLayoutWidth = self.bounds.size.width;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.mealTitleTextView.contentInset = UIEdgeInsetsMake(0, -5, 0, -5);
    self.mealTitleTextView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - Public Methods

- (void)setMenuItem:(MITDiningMenuItem *)menuItem
{
    if ([menuItem isEqual:_menuItem]) {
        return;
    }
    
    self.stationLabel.text = menuItem.station;
    if ([menuItem.itemDescription length] > 0) {
        self.mealDescriptionLabel.text = menuItem.itemDescription;
    }
    else {
        self.mealDescriptionLabel.text = @"";
    }

    NSMutableAttributedString *dietaryFlagString = [[NSMutableAttributedString alloc] initWithAttributedString:[menuItem attributedNameWithDietaryFlagsAtSize:CGSizeMake(20, 20) verticalAdjustment:-5]];
    [dietaryFlagString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17] range:NSMakeRange(0, dietaryFlagString.length)];
    self.mealTitleTextView.attributedText = [[NSAttributedString alloc] initWithAttributedString:dietaryFlagString];
    
    _menuItem = menuItem;
}

#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange
{
    if (![self.menuItem.dietaryFlags isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    __block BOOL foundFlag = NO;
    __block NSUInteger lastFlagLocation = 0;
    [self.mealTitleTextView.attributedText enumerateAttributesInRange:NSMakeRange(0, self.mealTitleTextView.attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:NSAttachmentAttributeName]) {
            foundFlag = YES;
            lastFlagLocation = range.location;
        }
    }];
    
    if (foundFlag) {
        MITDiningDietaryFlagListViewController *flagsVC = [[MITDiningDietaryFlagListViewController alloc] init];
        flagsVC.flags = self.menuItem.dietaryFlags;
        self.dietaryFlagPopoverController = [[UIPopoverController alloc] initWithContentViewController:flagsVC];
        self.dietaryFlagPopoverController.popoverContentSize = [flagsVC targetTableViewSize];
        
        NSRange flagsGlyphRange = [self.mealTitleTextView.layoutManager glyphRangeForCharacterRange:NSMakeRange(lastFlagLocation, 1) actualCharacterRange:NULL];
        CGRect dietaryFlagRect = [self.mealTitleTextView.layoutManager boundingRectForGlyphRange:flagsGlyphRange inTextContainer:self.mealTitleTextView.textContainer];
        [self.dietaryFlagPopoverController presentPopoverFromRect:dietaryFlagRect inView:self.mealTitleTextView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
    return NO;
}

#pragma mark - Determining Dynamic Cell Height

+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem width:(CGFloat)width
{
    MITDiningHallMealCollectionCell *sizingCell = [MITDiningHallMealCollectionCell sizingCell];
    [sizingCell setMenuItem:menuItem];
    return [MITDiningHallMealCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITDiningHallMealCollectionCell *)cell width:(CGFloat)width
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return MAX(44, height);
}

+ (MITDiningHallMealCollectionCell *)sizingCell
{
    static MITDiningHallMealCollectionCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningHallMealCollectionCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
