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

@end
