#import <UIKit/UIKit.h>

@class CalendarEventsViewController;

@interface EventCategoriesTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) CalendarEventsViewController *parentViewController;
@property (nonatomic, copy) NSArray *categories;

- (BOOL)isSubcategoryView;

@end
