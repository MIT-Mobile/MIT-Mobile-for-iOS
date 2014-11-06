
#import "MITLibrariesFormSheetCellSingleLineTextEntry.h"
#import "MITLibrariesFormSheetElement.h"

NSString * const MITLibrariesFormSheetCellSingleLineTextEntryNibName = @"MITLibrariesFormSheetCellSingleLineTextEntry";

@interface MITLibrariesFormSheetCellSingleLineTextEntry () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) MITLibrariesFormSheetElement *element;
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
    self.element = element;
}

+ (CGFloat)heightForCell
{
    return 44.0;
}

#pragma mark - TextFieldTextDidChange

- (void)textFieldTextDidChange:(UITextField *)textField
{
    self.element.value = textField.text;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
