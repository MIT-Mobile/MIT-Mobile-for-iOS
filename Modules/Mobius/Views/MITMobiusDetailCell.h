#import <UIKit/UIKit.h>

@interface MITMobiusDetailCell : UITableViewCell

+ (UINib *)detailCellNib;
+ (NSString *)detailCellNibName;

- (void)setTitle:(NSString *)title;
- (void)setStatus:(NSString *)status;

@end
