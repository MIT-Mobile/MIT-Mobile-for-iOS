#import "TextAreaLibraryFormElement.h"
#import "PlaceholderTextView.h"
#import "LibraryEmailFormViewController.h"
#import "MITUIConstants.h"

@implementation TextAreaLibraryFormElement
@synthesize textView;

- (void)dealloc {
    self.textView = nil;
}

- (void)updateCell:(UITableViewCell *)tableViewCell { }

- (UITableViewCell *)tableViewCell {
    self.textView = (PlaceholderTextView *)[self textInputView];
    self.textView.placeholder = self.displayLabel;
    self.textView.inputAccessoryView = self.formViewController.formInputAccessoryView;
    self.textView.font = [UIFont systemFontOfSize:CELL_STANDARD_FONT_SIZE];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key];
    UIEdgeInsets textFieldInsets = UIEdgeInsetsMake(4., 4., 4., 4.);
    self.textView.frame = UIEdgeInsetsInsetRect(cell.contentView.bounds, textFieldInsets);
    self.textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight);
    self.textView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView addSubview:self.textView];
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 110;
}

- (UIView *)textInputView {
    if (!self.textView) {
        self.textView = [[PlaceholderTextView alloc] init];
        self.textView.tag = kLibraryEmailFormTextView;
    }
    
    return self.textView;
}

- (NSString *)value {
    return self.textView.text;
}

@end
