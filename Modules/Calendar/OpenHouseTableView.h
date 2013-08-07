#import <UIKit/UIKit.h>
#define OPEN_HOUSE_START_DATE 1304213441

@class CalendarEventsViewController;

@interface OpenHouseTableView : UITableView <UITableViewDelegate, UITableViewDataSource>
@property (copy) NSArray *categories;
@property (weak) CalendarEventsViewController *parentViewController;

@end
