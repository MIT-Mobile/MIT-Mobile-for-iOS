#import "ExternalLinkLibraryFormElement.h"
#import "UIKit+MITAdditions.h"

@implementation ExternalLinkLibraryFormElement
- (UITableViewCell *)tableViewCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.key];
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 46;
}

- (void)updateCell:(UITableViewCell *)tableViewCell {
    tableViewCell.textLabel.text = self.displayLabel;
    tableViewCell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
}

- (NSString *)displayLabel
{
    return self.rawDisplayLabel;
}

@end
