#import <UIKit/UIKit.h>

@interface MITTitleDescriptionCell : UITableViewCell

+ (NSString *)titleDescriptionCellNibName;
+ (UINib *)titleDescriptionCellNib;
- (void)setTitle:(NSString *)title setDescription:(NSString *)description;

@end
