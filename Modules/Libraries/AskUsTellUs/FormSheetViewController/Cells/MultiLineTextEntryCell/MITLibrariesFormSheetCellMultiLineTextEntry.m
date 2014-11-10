#import "MITLibrariesFormSheetCellMultiLineTextEntry.h"
#import "PlaceholderTextView.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellMultiLineTextEntryNibName = @"MITLibrariesFormSheetCellMultiLineTextEntry";

@interface MITLibrariesFormSheetCellMultiLineTextEntry () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet PlaceholderTextView *textView;
@end

@implementation MITLibrariesFormSheetCellMultiLineTextEntry

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textView.delegate = self;
}

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textView.placeholder = element.title;
    self.textView.text = element.value;
}

+ (CGFloat)heightForCell
{
    return 160.0;
}

#pragma mark - UITextFiewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *textToSend = textView.text.length > 0 ? textView.text : nil;
    [self.delegate textEntryCell:self didUpdateValue:textToSend];
}

@end
