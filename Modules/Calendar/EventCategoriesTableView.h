#import <UIKit/UIKit.h>

@class CalendarEventsViewController;

@interface EventCategoriesTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {

	NSArray *categories;
	CalendarEventsViewController *parentViewController;
	
}

@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) CalendarEventsViewController *parentViewController;

- (BOOL)isSubcategoryView;

@end
