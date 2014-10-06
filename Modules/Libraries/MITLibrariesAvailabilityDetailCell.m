#import "MITLibrariesAvailabilityDetailCell.h"
#import "MITLibrariesAvailability.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesAvailabilityDetailCell ()

@property (nonatomic, weak) IBOutlet UILabel *callNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *collectionLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@end

@implementation MITLibrariesAvailabilityDetailCell

- (void)awakeFromNib
{
    [self.callNumberLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.collectionLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    [self.statusLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.callNumberLabel.preferredMaxLayoutWidth = self.callNumberLabel.bounds.size.width;
    self.collectionLabel.preferredMaxLayoutWidth = self.collectionLabel.bounds.size.width;
    self.statusLabel.preferredMaxLayoutWidth = self.statusLabel.bounds.size.width;
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
    self.collectionLabel.text = availability.collection;
    self.statusLabel.text = availability.status;
}

#pragma mark - Cell Sizing

+ (CGFloat)heightForAvailability:(MITLibrariesAvailability *)availability tableViewWidth:(CGFloat)width
{
    [[[self class] sizingCell] setAvailability:availability];
    return [[self class] heightForCell:[[self class] sizingCell] tableWidth:width];
}

+ (CGFloat)heightForCell:(MITLibrariesAvailabilityDetailCell *)cell tableWidth:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = width;
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height; // add pixel for cell separator
    return MAX(69, height);
}

+ (instancetype)sizingCell
{
    static MITLibrariesAvailabilityDetailCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [cellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
