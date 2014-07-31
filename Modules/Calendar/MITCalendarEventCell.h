#import <UIKit/UIKit.h>
#import "MITCalendarsEvent.h"

@interface MITCalendarEventCell : UITableViewCell

- (void)setEvent:(MITCalendarsEvent *)event;
+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
           tableViewWidth:(CGFloat)width;

@end
