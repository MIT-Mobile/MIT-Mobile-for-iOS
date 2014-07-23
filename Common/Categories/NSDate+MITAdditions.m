#import "NSDate+MITAdditions.h"

@implementation NSDate (MITAdditions)

+ (NSDate *)startDateForCurrentWeek {
    NSDate *currentDate = [NSDate date];
    return [currentDate startOfWeek];
}

- (NSDate *)startOfWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *currentDateWeekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
    NSDateComponents *dateComponentsToSubtract = [[NSDateComponents alloc] init];
    dateComponentsToSubtract.day = calendar.firstWeekday - currentDateWeekdayComponents.weekday;
    NSDate *startDate = [calendar dateByAddingComponents:dateComponentsToSubtract toDate:self options:0];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:startDate];
    return [calendar dateFromComponents:components];
}

- (NSDate *)endOfWeek {
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.week = 1;
    componentsToAdd.second = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:[self startOfWeek] options:0];
}

- (NSDate *)dateByAddingWeek {
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.week = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dateBySubtractingWeek {
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.week = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)beginningOfDay
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:self];
    
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    
    return [cal dateFromComponents:components];
}

- (NSTimeInterval)timeIntervalSinceStartOfDay {
    return [self timeIntervalSinceDate:[self beginningOfDay]];
}

- (MITDayOfTheWeek)dayOfTheWeek
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"E"];
    [dateFormatter setShortWeekdaySymbols:@[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7"]];
    
    return [[dateFormatter stringFromDate:self] integerValue];
}

+ (NSArray *)hoursInADay
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ha"];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[NSDate date]];
    
    NSMutableArray *hoursInADay = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 24; i ++)
    {
        if (i == 0 || i == 12 || i == 23)
        {
            components.hour = i;
            [hoursInADay addObject:[formatter stringFromDate:[cal dateFromComponents:components]]];
        }
        else
        {
            int hour = i;
            if (hour > 12) hour -= 12;
            [hoursInADay addObject:[NSString stringWithFormat:@"%d", hour]];
        }
        
    }
    return hoursInADay;
}

@end
