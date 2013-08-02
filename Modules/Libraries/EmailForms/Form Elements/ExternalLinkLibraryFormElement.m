#import "ExternalLinkLibraryFormElement.h"

@implementation ExternalLinkLibraryFormElement
- (UITableViewCell *)tableViewCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key]];
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 46;
}

- (NSString *)value {
    return nil;
}

- (void)updateCell:(UITableViewCell *)tableViewCell {
    tableViewCell.textLabel.text = self.displayLabel;
    tableViewCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
}

- (UIView *)textInputView {
    return nil;
}


@end
