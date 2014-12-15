#import "MITMapPlaceCell.h"

const CGFloat kMapPlaceCellEstimatedHeight = 50.0;

@interface MITMapPlaceCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation MITMapPlaceCell

- (void)awakeFromNib
{
    [self refreshLabelLayoutWidths];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutIfNeeded];
    [self refreshLabelLayoutWidths];
}

- (void)refreshLabelLayoutWidths
{
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.frame.size.width;
    self.subtitleLabel.preferredMaxLayoutWidth = self.subtitleLabel.frame.size.width;
}

#pragma mark - Place

- (void)setPlace:(MITMapPlace *)place
{
    self.titleLabel.text = place.title;
    self.subtitleLabel.text = place.subtitle;
}

- (void)setPlace:(MITMapPlace *)place order:(NSInteger)order
{
    self.titleLabel.text = [NSString stringWithFormat:@"%ld. %@", (long)order, place.title];
    self.subtitleLabel.text = place.subtitle;
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForPlace:(MITMapPlace *)place
                    order:(NSInteger)order
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    [[MITMapPlaceCell sizingCell] setPlace:place order:order];
    return [MITMapPlaceCell heightForCell:[MITMapPlaceCell sizingCell] TableWidth:width accessoryType:accessoryType];
}

+ (CGFloat)heightForPlace:(MITMapPlace *)place
           tableViewWidth:(CGFloat)width
            accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    [[MITMapPlaceCell sizingCell] setPlace:place];
    return [MITMapPlaceCell heightForCell:[MITMapPlaceCell sizingCell] TableWidth:width accessoryType:accessoryType];
}

+ (CGFloat)heightForCell:(MITMapPlaceCell *)cell TableWidth:(CGFloat)width accessoryType:(UITableViewCellAccessoryType)accessoryType
{
    cell.accessoryType = accessoryType;
    
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(kMapPlaceCellEstimatedHeight, height);
}

+ (MITMapPlaceCell *)sizingCell
{
    static MITMapPlaceCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITMapPlaceCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}


@end
