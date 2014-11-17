#import <UIKit/UIKit.h>

@class MITCalendarPageViewController, MITCalendarsCalendar, MITCalendarsEvent;

@protocol MITCalendarPageViewControllerDelegate <NSObject>

@optional

- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                    didSwipeToDate:(NSDate *)date;
- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
                     didSelectEvent:(MITCalendarsEvent *)event;
- (void)calendarPageViewController:(MITCalendarPageViewController *)viewController
  didUpdateCurrentlyDisplayedEvents:(NSArray *)currentlyDisplayedEvents;

@end

@interface MITCalendarPageViewController : UIPageViewController

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) MITCalendarsCalendar *calendar;
@property (nonatomic, strong) MITCalendarsCalendar *category;

@property (nonatomic, weak) id<MITCalendarPageViewControllerDelegate>calendarSelectionDelegate;

- (void)moveToCalendar:(MITCalendarsCalendar *)calendar category:(MITCalendarsCalendar *)category date:(NSDate *)date animated:(BOOL)animated;

@property (nonatomic) BOOL shouldIndicateCellSelectedState;

@end
