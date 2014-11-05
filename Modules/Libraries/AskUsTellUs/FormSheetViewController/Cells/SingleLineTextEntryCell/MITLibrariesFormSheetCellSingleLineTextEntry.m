
#import "MITLibrariesFormSheetCellSingleLineTextEntry.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellSingleLineTextEntryNibName = @"MITLibrariesFormSheetCellSingleLineTextEntry";

@interface MITLibrariesFormSheetCellSingleLineTextEntry ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end

@implementation MITLibrariesFormSheetCellSingleLineTextEntry

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textField.placeholder = element.title;
    self.textField.text = element.value;
}

+ (CGFloat)heightForCell
{
    return 44.0;
}

@end
