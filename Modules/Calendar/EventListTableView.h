#import <UIKit/UIKit.h>
#import "CalendarEventsViewController.h"

@interface EventListTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {

	NSArray *events;
	BOOL isSearchResults;
	CalendarEventsViewController *parentViewController;
	NSIndexPath *previousSelectedIndexPath;
    NSString *searchSpan; // get this from server, e.g. "7 days"
	
}

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, assign) BOOL isSearchResults;
@property (nonatomic, assign) CalendarEventsViewController *parentViewController;
@property (nonatomic, retain) NSString *searchSpan;

@end
