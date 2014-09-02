#import "MITDiningFiltersCell.h"
#import "MITDiningMenuItem.h"

static CGFloat const kMITDiningFiltersCellEstimatedHeight = 35.0;

@interface MITDiningFiltersCell ()

@property (weak, nonatomic) IBOutlet UILabel *showingLabel;
@property (weak, nonatomic) IBOutlet UILabel *filtersLabel;

@end

@implementation MITDiningFiltersCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
    
    self.showingLabel.textColor = 
    self.filtersLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
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
    self.filtersLabel.attributedText = [MITDiningMenuItem dietaryFlagsDisplayStringForFlags:[filters allObjects]];
    
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
