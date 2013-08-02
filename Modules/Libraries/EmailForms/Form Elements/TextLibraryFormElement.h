#import "LibraryFormElement.h"

@interface TextLibraryFormElement : LibraryFormElement <UITextFieldDelegate>
@property (nonatomic, retain) UITextField *textField;
@property (assign) UIKeyboardType keyboardType;

@end

