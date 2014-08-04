#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITDayOfTheWeek) {
    MITDayOfTheWeekSunday,
    MITDayOfTheWeekMonday,
    MITDayOfTheWeekTuesday,
    MITDayOfTheWeekWednesday,
    MITDayOfTheWeekThursday,
    MITDayOfTheWeekFriday,
    MITDayOfTheWeekSaturday
};

@interface NSDate (MITAdditions)

+ (NSDate *)startDateForCurrentWeek;

- (NSString *)ISO8601String;

- (NSDate *)startOfWeek;
- (NSDate *)endOfWeek;
- (NSDate *)dateByAddingWeek;
- (NSDate *)dateBySubtractingWeek;
- (NSDate *)dateByAddingDay;
- (NSDate *)dateWithoutTime;

- (NSArray *)datesInWeek;
- (BOOL)isSameDayAsDate:(NSDate *)date;

- (NSDate *)beginningOfDay;
- (NSDate *)endOfDay;
- (NSTimeInterval)timeIntervalSinceStartOfDay;

- (MITDayOfTheWeek)dayOfTheWeek;

+ (NSArray *)hoursInADay;

@end
