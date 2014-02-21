#import "TextAreaLibraryFormElement.h"
#import "PlaceholderTextView.h"
#import "LibraryEmailFormViewController.h"
#import "MITUIConstants.h"

@implementation TextAreaLibraryFormElement

- (UITableViewCell *)tableViewCell {
    self.textView = (PlaceholderTextView *)[self textInputView];
    self.textView.placeholder = self.displayLabel;
    self.textView.inputAccessoryView = self.formViewController.formInputAccessoryView;
    self.textView.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    self.textView.scrollsToTop = NO;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key];
    UIEdgeInsets textFieldInsets = UIEdgeInsetsMake(0., 9., 0., 9.);
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        textFieldInsets = UIEdgeInsetsMake(0., 2., 0., 2.);
    }
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
