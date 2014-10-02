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

- (void)setContent:(id)content
{
    MITLibrariesLibrary *library = (MITLibrariesLibrary *)content;
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

+ (MITAutoSizingCell *)sizingCell
{
    static MITLibrariesLibraryCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

+ (CGFloat)estimatedCellHeight
{
    return 67.0;
}

@end