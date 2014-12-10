#import <UIKit/UIKit.h>

@class MITCalendarSelectionViewController;
@class MITCalendarsCalendar;

@protocol MITCalendarSelectionDelegate <NSObject>

- (void)calendarSelectionViewController:(MITCalendarSelectionViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category;

@end

@interface MITCalendarSelectionViewController : UITableViewController <MITCalendarSelectionDelegate>

@property (nonatomic, strong) MITCalendarsCalendar *category;

@property (nonatomic, weak) id<MITCalendarSelectionDelegate> delegate;

/*  These are used to track the ids of the selected calendars in order. Since a
    calendar can have multiple parents, we keep track of the selection order 
    here. For example, calendar 52 might be accessible from calendar 10 or 19, 
    so we need to keep track if the user selected 10 -> 52 or 19 -> 52 when we
    show the highlighted calendar disclosure/check mark. */
@property (nonatomic, strong) NSMutableArray *categoriesPath;

@property (nonatomic, assign) BOOL shouldHideRegistrar;

@end
