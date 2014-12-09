#import "MITLibrariesLibraryCell.h"
#import "MITLibrariesLibrary.h"
#import "UIKit+MITAdditions.h"

@interface MITLibrariesLibraryCell ()

@property (weak, nonatomic) IBOutlet UILabel *libraryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *libraryHoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *openClosedLabel;

@end

@implementation MITLibrariesLibraryCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.libraryHoursLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)setContent:(MITLibrariesLibrary *)library
{
    self.libraryNameLabel.text = library.name;
    self.libraryHoursLabel.text = [library hoursStringForDate:[NSDate date]];
    if ([library isOpenAtDate:[NSDate date]]) {
        self.openClosedLabel.text = @"Open";
        self.openClosedLabel.textColor = [UIColor mit_openGreenColor];
    }
    else {
        self.openClosedLabel.text = @"Closed";
        self.openClosedLabel.textColor = [UIColor mit_closedRedColor];
    }
    
    [self layoutIfNeeded];
}

+ (CGFloat)estimatedCellHeight
{
    return 67.0;
}

@end