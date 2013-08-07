#import <UIKit/UIKit.h>
#import "CalendarEventsViewController.h"

@interface EventListTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) CalendarEventsViewController *parentViewController;
@property (nonatomic, getter = isSearchResults) BOOL searchResults;
@property (copy) NSArray *events;
@property (copy) NSString *searchSpan;

@end
