#import <UIKit/UIKit.h>
@class MITCalendarsEvent;

@interface MITAcademicCalendarCell : UITableViewCell

- (void)setEvent:(MITCalendarsEvent *)event;

+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
           tableViewWidth:(CGFloat)width;

@end
