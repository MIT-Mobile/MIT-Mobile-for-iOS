#import <UIKit/UIKit.h>

@interface MITMartyDetailCell : UITableViewCell

+ (UINib *)detailCellNib;
+ (NSString *)detailCellNibName;

- (void)setTitle:(NSString *)title;
- (void)setStatus:(NSString *)status;

@end
