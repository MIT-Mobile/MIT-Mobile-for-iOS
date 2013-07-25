#import <UIKit/UIKit.h>

@class CalendarEventsViewController;

@interface EventCategoriesTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, weak) CalendarEventsViewController *parentViewController;

- (BOOL)isSubcategoryView;

@end
