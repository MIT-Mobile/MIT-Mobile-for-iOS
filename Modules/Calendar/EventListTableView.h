#import <UIKit/UIKit.h>
#import "CalendarEventsViewController.h"

@interface EventListTableView : UITableView <UITableViewDelegate, UITableViewDataSource> 

@property (nonatomic, strong) NSArray *events;
@property (nonatomic, getter = isSearchResults) BOOL searchResults;
@property (nonatomic, weak) CalendarEventsViewController *parentViewController;
@property (nonatomic, strong) NSString *searchSpan;

@end
