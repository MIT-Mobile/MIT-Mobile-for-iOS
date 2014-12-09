#import "MITLibrariesHoldingLibraryHeaderCell.h"
#import "UIKit+MITLibraries.h"

@implementation MITLibrariesHoldingLibraryHeaderCell

- (void)awakeFromNib {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.libraryNameLabel setLibrariesTextStyle:MITLibrariesTextStyleTitle];
    [self.libraryHoursLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    [self.availableCopiesLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
}

@end
