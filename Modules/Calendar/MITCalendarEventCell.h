#import <UIKit/UIKit.h>
#import "MITCalendarEvent.h"

@interface MITCalendarEventCell : UITableViewCell

- (void)setEvent:(MITCalendarEvent *)event;
+ (CGFloat)heightForEvent:(MITCalendarEvent *)event
           tableViewWidth:(CGFloat)width;

@end
