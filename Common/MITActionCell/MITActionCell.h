#import <UIKit/UIKit.h>
#import "MITEventDetailViewController.h"

@interface MITActionCell : UITableViewCell

- (void)setTitle:(NSString *)title;
- (void)setDetailText:(NSString *)detailText;
- (void)setupCellOfType:(MITEventDetailRowType)type withDetailText:(NSString *)detailText;

@end
