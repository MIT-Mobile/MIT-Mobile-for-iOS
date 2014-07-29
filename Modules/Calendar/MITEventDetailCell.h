#import <UIKit/UIKit.h>
#import "MITEventDetailViewController.h"

@interface MITEventDetailCell : UITableViewCell

- (void)setTitle:(NSString *)title;
- (void)setDetailText:(NSString *)detailText;
- (void)setIconForRowType:(MITEventDetailRowType)rowType;

@end
