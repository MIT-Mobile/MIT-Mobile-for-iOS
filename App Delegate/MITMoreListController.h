#import <UIKit/UIKit.h>

@class MITTabBarController;

DEPRECATED_ATTRIBUTE
@interface MITMoreListController : UITableViewController {
    MITTabBarController *theTabBarController;
}

@property (nonatomic, retain) MITTabBarController *theTabBarController;

@end

@class TableCellBadgeView;
DEPRECATED_ATTRIBUTE
@interface MITMoreListTableViewCell : UITableViewCell {
	TableCellBadgeView *badgeView;
}

@property (retain) NSString *badgeValue;

@end

DEPRECATED_ATTRIBUTE
@interface TableCellBadgeView : UIView {
	NSString *badgeValue;
}

@property (retain) NSString *badgeValue;

@end

