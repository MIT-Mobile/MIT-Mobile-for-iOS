
#import "MITLibrariesFormSheetCellOptions.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellOptionsNibName = @"MITLibrariesFormSheetCellOptions";

@implementation MITLibrariesFormSheetCellOptions

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textLabel.text = element.title;
    self.detailTextLabel.text = element.value;
}

+ (CGFloat)heightForCell
{
    return 44.0;
}

@end
