#import <UIKit/UIKit.h>
#import "MITEventList.h"

@class MITCalendarSelectionHomeViewController;
@class MITCalendarsCalendar;

@protocol MITCalendarSelectionDelegate <NSObject>

- (void)calendarSelectionViewController:(MITCalendarSelectionHomeViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category;

@end

@interface MITCalendarSelectionHomeViewController : UITableViewController

//@property (nonatomic, strong) NSArray *categories;

@property (nonatomic, weak) id<MITCalendarSelectionDelegate> delegate;

@end
