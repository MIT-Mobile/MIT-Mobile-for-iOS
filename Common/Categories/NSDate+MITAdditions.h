#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MITDayOfTheWeek) {
    MITDayOfTheWeekSunday,
    MITDayOfTheWeekMonday,
    MITDayOfTheWeekTuesday,
    MITDayOfTheWeekWednesday,
    MITDayOfTheWeekThursday,
    MITDayOfTheWeekFriday,
    MITDayOfTheWeekSaturday,
    MITDayOfTheWeekOther
};

@interface NSDate (MITAdditions)

+ (NSDate *)startDateForCurrentWeek;

- (NSDate *)startOfWeek;
- (NSDate *)endOfWeek;
- (NSDate *)dateByAddingWeek;
- (NSDate *)dateBySubtractingWeek;

- (NSDate *)beginningOfDay;
- (NSTimeInterval)timeIntervalSinceStartOfDay;

- (MITDayOfTheWeek)dayOfTheWeek;

+ (NSArray *)hoursInADay;

@end
