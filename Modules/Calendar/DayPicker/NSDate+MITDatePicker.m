#import "NSDate+MITDatePicker.h"

@implementation NSDate (MITDatePicker)

- (BOOL)dp_isEqualToDateIgnoringTime:(NSDate *)aDate
{
    return [self dp_isEqualToDate:aDate
                    components:(NSYearCalendarUnit |
                                NSMonthCalendarUnit |
                                NSDayCalendarUnit)];
}

- (BOOL)dp_isEqualToDate:(NSDate*)aDate
            components:(NSCalendarUnit)components
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date1 = [calendar dateFromComponents:[calendar components:components
                                                             fromDate:self]];
    NSDate *date2 = [calendar dateFromComponents:[calendar components:components
                                                             fromDate:aDate]];
    
    return [date1 isEqual:date2];
}

- (NSArray *)dp_datesInWeek
{
    NSDate *day = [self dp_startOfWeek];
    NSMutableArray *datesInWeek = [[NSMutableArray alloc] initWithArray:@[day]];
    for (int i = 0; i < 6; i++) {
        day = [day dp_dateByAddingDay];
        [datesInWeek addObject:day];
    }
    return [datesInWeek copy];
}

- (NSDate *)dp_startOfWeek
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *currentDateWeekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
    NSDateComponents *dateComponentsToSubtract = [[NSDateComponents alloc] init];
    dateComponentsToSubtract.day = calendar.firstWeekday - currentDateWeekdayComponents.weekday;
    NSDate *startDate = [calendar dateByAddingComponents:dateComponentsToSubtract toDate:self options:0];
    NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:startDate];
    return [calendar dateFromComponents:components];
}

- (NSDate *)dp_dateByAddingDay
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.day = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dp_dateByAddingWeek
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.weekOfYear = 1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dp_dateBySubtractingDay
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.day = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dp_dateBySubtractingWeek
{
    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
    componentsToAdd.weekOfYear = -1;
    return [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd toDate:self options:0];
}

- (NSDate *)dp_startOfDay
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [calendar dateFromComponents:[calendar components:(NSYearCalendarUnit |
                                                              NSMonthCalendarUnit |
                                                              NSDayCalendarUnit)
                                                    fromDate:self]];
}

- (BOOL)dp_dateFallsBetweenStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    return ([self timeIntervalSince1970] >= [startDate timeIntervalSince1970] &&
            [self timeIntervalSince1970] <= [endDate timeIntervalSince1970]);
}



@end
