#import "MITDiningMenuItemCell.h"
#import "MITDiningMenuItem.h"
#import "UIKit+MITAdditions.h"

static CGFloat kMITDiningMenuItemCellEstimatedHeight = 44.0;

@interface MITDiningMenuItemCell ()

@property (weak, nonatomic) IBOutlet UILabel *stationLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ingredientsLabel;

@end

@implementation MITDiningMenuItemCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.stationLabel.textColor =
    self.ingredientsLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.stationLabel.preferredMaxLayoutWidth = self.stationLabel.frame.size.width;
    self.itemNameLabel.preferredMaxLayoutWidth = self.itemNameLabel.frame.size.width;
    self.ingredientsLabel.preferredMaxLayoutWidth = self.ingredientsLabel.frame.size.width;
}

#pragma mark - Venue Setup

- (void)setMenuItem:(MITDiningMenuItem *)menuItem
{
    self.stationLabel.text = menuItem.station;
    self.itemNameLabel.attributedText = [menuItem attributedNameWithDietaryFlagsAtSize:CGSizeMake(14, 14) verticalAdjustment:-2];
    self.ingredientsLabel.text = menuItem.itemDescription;
    
    [self layoutIfNeeded];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem
              tableViewWidth:(CGFloat)width;
{
    [[MITDiningMenuItemCell sizingCell] setMenuItem:menuItem];
    return [MITDiningMenuItemCell heightForCell:[MITDiningMenuItemCell sizingCell] TableWidth:width];
}

+ (CGFloat)heightForCell:(MITDiningMenuItemCell *)cell TableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMITDiningMenuItemCellEstimatedHeight, height);
}

+ (MITDiningMenuItemCell *)sizingCell
{
    static MITDiningMenuItemCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITDiningMenuItemCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
