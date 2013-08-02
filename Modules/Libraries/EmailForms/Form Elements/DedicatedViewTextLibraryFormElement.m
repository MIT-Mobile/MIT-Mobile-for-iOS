#import "DedicatedViewTextLibraryFormElement.h"

@implementation DedicatedViewTextLibraryFormElement
- (void)updateCell:(UITableViewCell *)tableViewCell
{
    tableViewCell.detailTextLabel.text = [self textValue];
}

// This is for the cell in a form table not a LibraryTextElementViewController
// cell.
- (UITableViewCell *)tableViewCell
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:self.key];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = self.displayLabel;
    
    return cell;
}

- (CGFloat)heightForTableViewCell {
    return 44.;
}

- (UIView *)textInputView {
    return nil;
}

- (NSString *)value {
    return self.textValue;
}
@end
