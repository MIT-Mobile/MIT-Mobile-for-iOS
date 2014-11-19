#import <UIKit/UIKit.h>

@interface MITAcademicHolidaysCalendarViewController : UIViewController

- (void)scrollToDate:(NSDate *)date;
@property (strong, nonatomic) NSDate *currentlyDisplayedDate;

@end
