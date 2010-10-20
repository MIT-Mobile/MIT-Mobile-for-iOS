#import <UIKit/UIKit.h>

@class MITTabBarController;

@interface MITMoreListController : UITableViewController {
    MITTabBarController *theTabBarController;
}

@property (nonatomic, retain) MITTabBarController *theTabBarController;

@end

@class TableCellBadgeView;
@interface MITMoreListTableViewCell : UITableViewCell {
	TableCellBadgeView *badgeView;
}

@property (retain) NSString *badgeValue;

@end

@interface TableCellBadgeView : UIView {
	NSString *badgeValue;
}

@property (retain) NSString *badgeValue;

@end

