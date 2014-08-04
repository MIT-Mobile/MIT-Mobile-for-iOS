#import <Foundation/Foundation.h>

typedef void(^MITCalendarsCompletionBlock)(NSArray *calendars, NSError *error);
typedef void(^MITEventsCompletionBlock)(NSArray *events, NSError *error);

@class MITCalendarsCalendar;

@interface MITCalendarWebservices : NSObject

+ (void)getCalendarsWithCompletion:(MITCalendarsCompletionBlock)completion;
+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                        date:(NSDate *)date
                  completion:(MITEventsCompletionBlock)completion;
+ (void)getEventsWithinOneMonthInCalendar:(MITCalendarsCalendar *)calendar forQuery:(NSString *)query completion:(MITEventsCompletionBlock)completion;
+ (void)getEventsWithinOneYearInCalendar:(MITCalendarsCalendar *)calendar forQuery:(NSString *)query completion:(MITEventsCompletionBlock)completion;

+ (void)getEventsForCalendar:(MITCalendarsCalendar *)calendar
                 queryString:(NSString *)queryString
                    category:(MITCalendarsCalendar *)category
                   startDate:(NSDate *)startDate
                     endDate:(NSDate *)endDate
                  completion:(MITEventsCompletionBlock)completion;
@end
