#import <UIKit/UIKit.h>
#import "MITCalendarsEvent.h"

@interface MITCalendarEventCell : UITableViewCell

- (void)setEvent:(MITCalendarsEvent *)event withNumberPrefix:(NSString *)numberPrefix;
+ (CGFloat)heightForEvent:(MITCalendarsEvent *)event
         withNumberPrefix:(NSString *)numberPrefix
           tableViewWidth:(CGFloat)width;
- (void)updateForSelected:(BOOL)selected;
@end
