#import "MITLibrariesFormSheetCellWebLink.h"
#import "MITLibrariesFormSheetElement.h"
#import "UIKit+MITAdditions.h"

NSString * const MITLibrariesFormSheetCellWebLinkNibName = @"MITLibrariesFormSheetCellWebLink";

@implementation MITLibrariesFormSheetCellWebLink

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
}

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textLabel.text = element.title;
}

+ (CGFloat)heightForCell
{
    return 44.0;
}

@end
