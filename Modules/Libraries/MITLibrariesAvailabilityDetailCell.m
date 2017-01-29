#import "MITLibrariesAvailabilityDetailCell.h"
#import "MITLibrariesAvailability.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesAvailabilityDetailCell ()

@property (nonatomic, strong) MITLibrariesAvailability *availability;
@property (nonatomic, weak) IBOutlet UILabel *callNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *collectionLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@end

@implementation MITLibrariesAvailabilityDetailCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.callNumberLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.collectionLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    [self.statusLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)setContent:(MITLibrariesAvailability *)availability
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

+ (CGFloat)estimatedCellHeight
{
    return 69.0;
}

@end
