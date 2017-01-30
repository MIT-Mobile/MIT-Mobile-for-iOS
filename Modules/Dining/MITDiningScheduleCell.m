#import "MITDiningScheduleCell.h"
#import "UIKit+MITAdditions.h"
#import "MITDiningMealSummary.h"

static CGFloat const kMITDiningScheduleCellEstimatedHeight = 67.0;

@interface MITDiningScheduleCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateRangesLabel;
@property (weak, nonatomic) IBOutlet UILabel *mealNamesLabel;
@property (weak, nonatomic) IBOutlet UILabel *mealTimesLabel;

@end

@implementation MITDiningScheduleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self refreshLabelLayoutWidths];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.dateRangesLabel.textColor = [UIColor mit_tintColor];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.dateRangesLabel.preferredMaxLayoutWidth = self.dateRangesLabel.frame.size.width;
    self.mealNamesLabel.preferredMaxLayoutWidth = self.mealNamesLabel.frame.size.width;
    self.mealTimesLabel.preferredMaxLayoutWidth = self.mealTimesLabel.frame.size.width;
}

#pragma mark - Venue Setup

- (void)setMealSummary:(MITDiningMealSummary *)mealSummary
{
    self.dateRangesLabel.text = mealSummary.dateRangesString;
    if (![mealSummary.meals count]) {
        self.mealNamesLabel.text = @"Closed";
        self.mealTimesLabel.text = @"";
    } else {
        self.mealNamesLabel.text = mealSummary.mealNamesStringsOnSeparateLines;
        self.mealTimesLabel.text = mealSummary.mealTimesStringsOnSeparateLines;
    }
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForMealSummary:(MITDiningMealSummary *)mealSummary
                 tableViewWidth:(CGFloat)width
{
    [[MITDiningScheduleCell sizingCell] setMealSummary:mealSummary];
    return [MITDiningScheduleCell heightForCell:[MITDiningScheduleCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITDiningScheduleCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningScheduleCellEstimatedHeight, height);
}

+ (MITDiningScheduleCell *)sizingCell
{
    static MITDiningScheduleCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningScheduleCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
