#import <Foundation/Foundation.h>
#import "MITCalendarsCalendar.h"

@interface MITMasterCalendar : NSObject

@property (nonatomic, strong) MITCalendarsCalendar *eventsCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *academicHolidaysCalendar;

- (instancetype)initWithCalendarsArray:(NSArray *)array;

@end
