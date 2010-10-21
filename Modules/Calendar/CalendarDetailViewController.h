#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "CalendarConstants.h"
#import "ShareDetailViewController.h"

@class MITCalendarEvent;

@interface CalendarDetailViewController : ShareDetailViewController <UITableViewDelegate, UITableViewDataSource, JSONLoadedDelegate, ShareItemDelegate, UIWebViewDelegate> {
	
    BOOL isRegularEvent;
    
    MITMobileWebAPI *apiRequest;
    BOOL isLoading;
    
	MITCalendarEvent *event;
	CalendarEventListType* rowTypes;
	NSInteger numRows;
	
	UITableView *_tableView;
	UIButton *shareButton;
    UISegmentedControl *eventPager;
	
    NSInteger descriptionHeight;
	NSMutableString *descriptionString;
	
    CGFloat categoriesHeight;
	NSMutableString *categoriesString;

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

