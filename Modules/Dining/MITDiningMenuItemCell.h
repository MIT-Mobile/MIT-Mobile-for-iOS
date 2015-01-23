#import <UIKit/UIKit.h>

@class MITDiningMenuItem;

@interface MITDiningMenuItemCell : UITableViewCell

- (void)setMenuItem:(MITDiningMenuItem *)menuItem;
+ (CGFloat)heightForMenuItem:(MITDiningMenuItem *)menuItem
              tableViewWidth:(CGFloat)width;

@end
