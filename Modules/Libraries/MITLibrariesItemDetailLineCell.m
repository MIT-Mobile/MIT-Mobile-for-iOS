#import "MITLibrariesItemDetailLineCell.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesItemDetailLineCell ()

@end

@implementation MITLibrariesItemDetailLineCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.lineTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    [self.lineDetailLabel setLibrariesTextStyle:MITLibrariesTextStyleDetail];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.lineTitleLabel.preferredMaxLayoutWidth = self.lineTitleLabel.bounds.size.width;
    self.lineDetailLabel.preferredMaxLayoutWidth = self.lineDetailLabel.bounds.size.width;
    self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForTitle:(NSString *)title detail:(NSString *)detail tableViewWidth:(CGFloat)width
{
    MITLibrariesItemDetailLineCell *sizingCell = [[self class] sizingCell];
    sizingCell.lineTitleLabel.text = title;
    sizingCell.lineDetailLabel.text = detail;
    return [[self class] heightForCell:sizingCell tableWidth:width];
}

+ (CGFloat)heightForCell:(MITLibrariesItemDetailLineCell *)cell tableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(25, height);
}

+ (instancetype)sizingCell
{
    static MITLibrariesItemDetailLineCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [cellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
