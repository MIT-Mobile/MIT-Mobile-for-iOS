#import <UIKit/UIKit.h>

@protocol UITableViewDataSourceDynamicSizing;

@interface UITableView (DynamicSizing)
- (void)registerClass:(Class)cellClass forDynamicCellReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forDynamicCellReuseIdentifier:(NSString *)identifier;
- (CGFloat)minimumHeightForCellWithReuseIdentifier:(NSString*)reuseIdentifier atIndexPath:(NSIndexPath*)indexPath;
@end

@protocol UITableViewDataSourceDynamicSizing <UITableViewDataSource>
@required
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
@end