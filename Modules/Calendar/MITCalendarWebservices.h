#import <Foundation/Foundation.h>

typedef void(^MITCalendarsCompletionBlock)(NSArray *calendars, NSError *error);
typedef void(^MITEventsCompletionBlock)(NSArray *events, NSError *error);

@class MITCalendarsCalendar;

@interface MITCalendarWebservices : NSObject

+ (void)getCalendarsWithCompletion:(MITCalendarsCompletionBlock)completion;
+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                        date:(NSDate *)date
                  completion:(MITEventsCompletionBlock)completion;

@end
