
#import <UIKit/UIKit.h>

@interface DiningHallInfoScheduleCell : UITableViewCell

@property (nonatomic, strong) NSArray * scheduleInfo;

- (void) setStartDate:(NSDate *)startDate andEndDate:(NSDate *)endDate;

@end
