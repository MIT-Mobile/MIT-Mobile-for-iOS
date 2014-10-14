#import "MITMasterCalendar.h"

static NSString *const kEventsCalendarID = @"events_calendar";
static NSString *const kAcademicCalendarID = @"academic_calendar";
static NSString *const kAcademicHolidaysCalendarID = @"academic_holidays";

@implementation MITMasterCalendar

- (instancetype)initWithCalendarsArray:(NSArray *)array
{
    self = [super init];
    if (self) {
        for (MITCalendarsCalendar *calendar in array) {
            if ([calendar.identifier isEqualToString:kEventsCalendarID]) {
                self.eventsCalendar = calendar;
            }
            else if ([calendar.identifier isEqualToString:kAcademicCalendarID]) {
                self.academicCalendar = calendar;
            }
            else if ([calendar.identifier isEqualToString:kAcademicHolidaysCalendarID]) {
                self.academicHolidaysCalendar = calendar;
            }
        }
    }
    return self;
}

@end
