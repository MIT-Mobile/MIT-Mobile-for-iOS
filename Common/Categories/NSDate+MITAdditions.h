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

- (NSDate *)startOfWeek;
- (NSDate *)endOfWeek;
- (NSDate *)dateByAddingWeek;
- (NSDate *)dateBySubtractingWeek;
- (NSDate *)dateByAddingDay;

- (NSArray *)datesInWeek;
- (BOOL)isSameDayAsDate:(NSDate *)date;

- (NSDate *)beginningOfDay;
- (NSTimeInterval)timeIntervalSinceStartOfDay;

- (MITDayOfTheWeek)dayOfTheWeek;

+ (NSArray *)hoursInADay;

@end
