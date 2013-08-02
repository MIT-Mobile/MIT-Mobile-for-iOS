#import "LibraryFormElement.h"

@interface TextLibraryFormElement : LibraryFormElement <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property UIKeyboardType keyboardType;

@end

