#import "MITLibrariesFormSheetCellSingleLineTextEntry.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellSingleLineTextEntryNibName = @"MITLibrariesFormSheetCellSingleLineTextEntry";

@interface MITLibrariesFormSheetCellSingleLineTextEntry () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end

@implementation MITLibrariesFormSheetCellSingleLineTextEntry

- (void)awakeFromNib
{
    self.textField.delegate = self;
    [self.textField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)configureCellForFormSheetElement:(MITLibrariesFormSheetElement *)element
{
    self.textField.placeholder = element.title;
    self.textField.text = element.value;
}

+ (CGFloat)heightForCell
{
    return 44.0;
}

#pragma mark - TextFieldTextDidChange

- (void)textFieldTextDidChange:(UITextField *)textField
{
    NSString *textToSend = textField.text.length > 0 ? textField.text : nil;
    [self.delegate textEntryCell:self didUpdateValue:textToSend];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
