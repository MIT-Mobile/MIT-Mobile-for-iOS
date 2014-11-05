
#import "MITLibrariesFormSheetCellMultiLineTextEntry.h"
#import "PlaceholderTextView.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellMultiLineTextEntryNibName = @"MITLibrariesFormSheetCellMultiLineTextEntry";

@interface MITLibrariesFormSheetCellMultiLineTextEntry ()
@property (weak, nonatomic) IBOutlet PlaceholderTextView *textView;
@end

@implementation MITLibrariesFormSheetCellMultiLineTextEntry

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textView.placeholder = element.title;
    self.textView.text = element.value;
}

+ (CGFloat)heightForCell
{
    return 160.0;
}

@end
