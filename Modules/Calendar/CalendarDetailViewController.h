#import <UIKit/UIKit.h>
#import "ShareDetailViewController.h"
#import <EventKitUI/EventKitUI.h>

@class MITCalendarEvent;

typedef enum {
	CalendarDetailRowTypeTime,
	CalendarDetailRowTypeLocation,
	CalendarDetailRowTypePhone,
	CalendarDetailRowTypeURL,
	CalendarDetailRowTypeDescription,
	CalendarDetailRowTypeCategories
} CalendarDetailRowType;

@interface CalendarDetailViewController : ShareDetailViewController <
UITableViewDelegate, UITableViewDataSource, ShareItemDelegate, 
UIWebViewDelegate, EKEventEditViewDelegate>

@property (nonatomic, strong) MITCalendarEvent *event;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *events;

- (void)reloadEvent;
- (void)setupHeader;
- (void)setupShareButton;
- (void)requestEventDetails;
- (void)showNextEvent:(id)sender;

- (NSString *)htmlStringFromString:(NSString *)source;

@end

