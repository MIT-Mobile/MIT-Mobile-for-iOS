#import "MITCalendarManager.h"
#import "MITCalendarWebservices.h"

#import "MITCalendarsCalendar.h"

static NSString *const kEventsCalendarID = @"events_calendar";
static NSString *const kAcademicCalendarID = @"academic_calendar";
static NSString *const kAcademicHolidaysCalendarID = @"academic_holidays";

@implementation MITCalendarManager

+ (instancetype)sharedManager
{
    static MITCalendarManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MITCalendarManager alloc] init];
    });
    return manager;
}

- (void)loadCalendarsCompletion:(void (^)(BOOL))completion
{
    [MITCalendarWebservices getCalendarsWithCompletion:^(NSArray *calendars, NSError *error) {
        if (calendars) {
            for (MITCalendarsCalendar *calendar in calendars) {
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
            self.calendarsLoaded = YES;
            completion(YES);
        }
        else {
            NSLog(@"Error Fetching Calendars: %@", error);
            self.calendarsLoaded = NO;
            completion(NO);
        }
    }];
}

//- (void)loadEventsForCalendar:(MITCalendarsCalendar *)calendar completion:(MITCalendarManagerCompletionBlock)completion
//{
//    [self loadEentsForCalendar:calendar date:[NSDate date] completion:completion];
//}
//
//- (void)loadEentsForCalendar:(MITCalendarsCalendar *)calendar date:(NSDate *)date completion:(MITCalendarManagerCompletionBlock)completion
//{
//    [MITCalendarWebservices getEventsForCalendar:calendar date:date completion:^(NSArray *events, NSError *error) {
//        if (events) {
//            self.currentCalendar = calendar;
//            self.currentEvents = events;
//            completion(YES);
//        }
//        else {
//            completion(NO);
//        }
//    }];
//}

@end
