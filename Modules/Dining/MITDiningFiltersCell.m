#import "MITDiningFiltersCell.h"
#import "MITDiningMenuItem.h"
#import "UIKit+MITAdditions.h"

static CGFloat const kMITDiningFiltersCellEstimatedHeight = 35.0;

@interface MITDiningFiltersCell ()

@property (weak, nonatomic) IBOutlet UILabel *filtersLabel;

@end

@implementation MITDiningFiltersCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self refreshLabelLayoutWidths];
    
    self.filtersLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.filtersLabel.preferredMaxLayoutWidth = self.filtersLabel.frame.size.width;
}

#pragma mark - Venue Setup

- (void)setFilters:(NSSet *)filters;
{
    NSMutableAttributedString *showingString = [[NSMutableAttributedString alloc] initWithString:@"Showing "];
    [showingString appendAttributedString:[MITDiningMenuItem dietaryFlagsDisplayStringForFlags:[filters allObjects] atSize:CGSizeMake(14, 14) verticalAdjustment:-2]];
    
    self.filtersLabel.attributedText = showingString;
    
    [self layoutIfNeeded];
}

- (NSAttributedString *)attributedStringForFilters:(NSSet *)filters
{
    return nil;
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForFilters:(NSSet *)filters
             tableViewWidth:(CGFloat)width;
{
    [[MITDiningFiltersCell sizingCell] setFilters:filters];
    return [MITDiningFiltersCell heightForCell:[MITDiningFiltersCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITDiningFiltersCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningFiltersCellEstimatedHeight, height);
}

+ (MITDiningFiltersCell *)sizingCell
{
    static MITDiningFiltersCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningFiltersCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
