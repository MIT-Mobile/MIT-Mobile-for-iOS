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
UIWebViewDelegate, EKEventEditViewDelegate> {
	
    BOOL isLoading;
    
	MITCalendarEvent *event;
	CalendarDetailRowType* rowTypes;
	NSInteger numRows;
	
	UIButton *shareButton;
	
    CGFloat descriptionHeight;
	NSString *descriptionString;
	
    CGFloat categoriesHeight;
	NSString *categoriesString;

	// list of events to scroll through for previous/next buttons
	NSArray *events;
}

@property (nonatomic, retain) MITCalendarEvent *event;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *events;

- (void)reloadEvent;
- (void)setupHeader;
- (void)setupShareButton;
- (void)requestEventDetails;
- (void)showNextEvent:(id)sender;

- (NSString *)htmlStringFromString:(NSString *)source;

@end

