#import "TextLibraryFormElement.h"
#import "LibraryEmailFormViewController.h"
#import "MITUIConstants.h"

@implementation TextLibraryFormElement
- (id)initWithKey:(NSString *)key displayLabel:(NSString *)displayLabel required:(BOOL)required {
    self = [super initWithKey:key displayLabel:displayLabel required:required];
    if (self) {
        self.keyboardType = UIKeyboardTypeDefault;
    }
    return self;
}

- (void)dealloc {
    self.textField.delegate = nil;
}

- (UITableViewCell *)tableViewCell {
    self.textField = (UITextField *)[self textInputView];
    self.textField.font = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE];
    self.textField.placeholder = self.displayLabel;
    
    self.textField.inputAccessoryView = self.formViewController.formInputAccessoryView;
    self.textField.keyboardType = self.keyboardType;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key];
    UIEdgeInsets textFieldInsets = UIEdgeInsetsMake(4., 4., 4., 4.);
    self.textField.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds, textFieldInsets);
    self.textField.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight);
    self.textField.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:self.textField];
    
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 46;
}

- (UIView *)textInputView {
    if (!self.textField) {
        self.textField = [[UITextField alloc] init];
        self.textField.tag = kLibraryEmailFormTextField;
        self.textField.delegate = self;
    }
    
    return self.textField;
}

- (NSString *)value {
    return self.textField.text;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    return [self.formViewController textFieldShouldReturn:aTextField];
}

@end
