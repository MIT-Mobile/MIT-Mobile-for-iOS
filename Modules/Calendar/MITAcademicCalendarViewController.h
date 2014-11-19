#import <UIKit/UIKit.h>

@interface MITAcademicCalendarViewController : UIViewController

- (void)scrollToDate:(NSDate *)date;
@property (strong, nonatomic) NSDate *currentlyDisplayedDate;

@end
