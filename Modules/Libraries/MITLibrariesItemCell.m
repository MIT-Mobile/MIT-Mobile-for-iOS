#import "MITLibrariesItemCell.h"
#import "MITLibrariesWorldcatItem.h"
#import "UIKit+MITLibraries.h"
#import "UIImageView+AFNetworking.h"

@implementation MITLibrariesItemCell

- (void)awakeFromNib
{
    [self.itemTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.yearAndAuthorLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.itemTitleLabel.preferredMaxLayoutWidth = self.bounds.size.width - self.itemTitleLabel.bounds.size.width - self.itemTitleLabel.frame.origin.x - self.itemTitleLabelHorizontalTrailingConstraint.constant - self.layoutMargins.right;
    self.yearAndAuthorLabel.preferredMaxLayoutWidth = self.bounds.size.width - self.yearAndAuthorLabel.bounds.size.width - self.yearAndAuthorLabel.frame.origin.x - self.yearAndAuthorLabelHorizontalTrailingConstraint.constant - self.layoutMargins.right;
}

- (void)setItem:(MITLibrariesWorldcatItem *)item
{
    if ([_item isEqual:item]) {
        return;
    }
    
    self.itemImageView.image = nil;
    [self.itemImageView setImageWithURL:[NSURL URLWithString:item.imageUrl]];
    
    self.itemTitleLabel.text = item.title;
    self.yearAndAuthorLabel.text = [NSString stringWithFormat:@"%@; %@", [item yearsString], [item authorsString]];
    
    _item = item;
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForItem:(MITLibrariesWorldcatItem *)item tableViewWidth:(CGFloat)width
{
    [[[self class] sizingCell] setItem:item];
    return [[self class] heightForCell:[[self class] sizingCell] tableWidth:width];
}

+ (CGFloat)heightForCell:(MITLibrariesItemCell *)cell tableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(105, height);
}

+ (instancetype)sizingCell
{
    static MITLibrariesItemCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
