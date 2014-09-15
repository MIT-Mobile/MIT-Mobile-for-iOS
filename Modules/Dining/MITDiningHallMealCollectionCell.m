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
    [self.mealTitleTextView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mealTitleTapped:)]];
}

- (void)mealTitleTapped:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (![self.menuItem.dietaryFlags isKindOfClass:[NSArray class]]) {
        return;
    } else if (((NSArray *)self.menuItem.dietaryFlags).count < 1) {
        return;
    }
    
    // We need to find the dietary flag images and search to see if the tap is in the bounding box for each of them
    // We search each one separately in case there is overflow due to lots of flags and/or a very long final word. Can't count on the bounding box for all of them together not to contain other areas
    NSMutableArray *flagRangesArray = [NSMutableArray array];
    [self.mealTitleTextView.attributedText enumerateAttributesInRange:NSMakeRange(0, self.mealTitleTextView.attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:NSAttachmentAttributeName]) {
            [flagRangesArray addObject:[NSValue valueWithRange:range]];
        }
    }];
    
    if (flagRangesArray.count > 0) {
        BOOL tapIsOnFlag = NO;
        CGPoint tapLocation = [tapGestureRecognizer locationInView:self.mealTitleTextView];
        
        for (NSValue *rangeValue in flagRangesArray) {
            NSRange flagCharacterRange = [rangeValue rangeValue];
            NSRange flagGlyphRange = [self.mealTitleTextView.layoutManager glyphRangeForCharacterRange:flagCharacterRange actualCharacterRange:NULL];
            CGRect flagBoundingBox = [self.mealTitleTextView.layoutManager boundingRectForGlyphRange:flagGlyphRange inTextContainer:self.mealTitleTextView.textContainer];
            if (CGRectContainsPoint(flagBoundingBox, tapLocation)) {
                tapIsOnFlag = YES;
                break;
            }
        }
        
        if (tapIsOnFlag) {
            MITDiningDietaryFlagListViewController *flagsVC = [[MITDiningDietaryFlagListViewController alloc] init];
            flagsVC.flags = self.menuItem.dietaryFlags;
            self.dietaryFlagPopoverController = [[UIPopoverController alloc] initWithContentViewController:flagsVC];
            self.dietaryFlagPopoverController.popoverContentSize = [flagsVC targetTableViewSize];
            
            NSRange lastFlagCharacterRange = [flagRangesArray.lastObject rangeValue];
            NSRange flagsGlyphRange = [self.mealTitleTextView.layoutManager glyphRangeForCharacterRange:lastFlagCharacterRange actualCharacterRange:NULL];
            CGRect dietaryFlagRect = [self.mealTitleTextView.layoutManager boundingRectForGlyphRange:flagsGlyphRange inTextContainer:self.mealTitleTextView.textContainer];
            [self.dietaryFlagPopoverController presentPopoverFromRect:dietaryFlagRect inView:self.mealTitleTextView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
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
