#import "MITLibrariesHoldingLibraryHeaderCopyInfoCell.h"
#import "UIKit+MITLibraries.h"
#import "MITLibrariesAvailability.h"

@interface MITLibrariesHoldingLibraryHeaderCopyInfoCell ()

@property (nonatomic, weak) IBOutlet UILabel *callNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *extraInfoLabel;

@end

@implementation MITLibrariesHoldingLibraryHeaderCopyInfoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.callNumberLabel setLibrariesTextStyle:MITLibrariesTextStyleDetail];
    [self.extraInfoLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.callNumberLabel.preferredMaxLayoutWidth = self.callNumberLabel.bounds.size.width;
    self.extraInfoLabel.preferredMaxLayoutWidth = self.extraInfoLabel.bounds.size.width;
    self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setAvailability:(MITLibrariesAvailability *)availability
{
    if ([_availability isEqual:availability]) {
        return;
    }
    
    _availability = availability;
    
    self.callNumberLabel.text = availability.callNumber;
    self.extraInfoLabel.text = [NSString stringWithFormat:@"%@; %@", availability.collection, availability.status];
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForItem:(MITLibrariesAvailability *)availability tableViewWidth:(CGFloat)width
{
    [[[self class] sizingCell] setAvailability:availability];
    return [[self class] heightForCell:[[self class] sizingCell] tableWidth:width];
}

+ (CGFloat)heightForCell:(MITLibrariesHoldingLibraryHeaderCopyInfoCell *)cell tableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(38, height);
}

+ (instancetype)sizingCell
{
    static MITLibrariesHoldingLibraryHeaderCopyInfoCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [cellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
