#import <UIKit/UIKit.h>
#define OPEN_HOUSE_START_DATE 1304213441

@class CalendarEventsViewController;

@interface OpenHouseTableView : UITableView <UITableViewDelegate, UITableViewDataSource> {

	NSArray *categories;
	CalendarEventsViewController *parentViewController;
	
}

@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) CalendarEventsViewController *parentViewController;

@end
