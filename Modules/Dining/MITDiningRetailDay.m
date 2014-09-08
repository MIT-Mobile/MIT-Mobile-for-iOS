#import "MITDiningRetailDay.h"
#import "MITDiningRetailVenue.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningRetailDay

@dynamic dateString;
@dynamic endTimeString;
@dynamic message;
@dynamic startTimeString;
@dynamic retailHours;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"date" : @"dateString",
                                                  @"start_time" : @"startTimeString",
                                                  @"end_time" : @"endTimeString"}];
    [mapping addAttributeMappingsFromArray:@[@"message"]];
    
    return mapping;
}

#pragma mark - Convenience Methods

- (NSString *)hoursSummary
{
    NSString *hoursSummary = nil;
    
    if (self.message) {
        hoursSummary = self.message;
    } else if (self.startTimeString  && self.endTimeString) {
        NSString *startString = [self.startTime MITShortTimeOfDayString];
        NSString *endString = [self.endTime MITShortTimeOfDayString];
        
        hoursSummary = [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    } else {
        hoursSummary = @"Closed for the day";
    }
    
    return hoursSummary;
}

#pragma mark - Open/Closed Status

- (NSString *)openClosedStatusRelativeToDate:(NSDate *)date
{
    NSString *openClosedStatus = @"Closed for the day";
    if (self.message) {
        openClosedStatus = self.message;
    } else {
        NSTimeInterval dateInterval = [date timeIntervalSince1970];
        NSTimeInterval bestMealStart = [self.startTime timeIntervalSince1970];
        NSTimeInterval bestMealEnd = [self.endTime timeIntervalSince1970];
        
        if (dateInterval < bestMealStart) {
            openClosedStatus = [NSString stringWithFormat:@"Opens at %@", [self.startTime MITShortTimeOfDayString]];
        } else if (dateInterval < bestMealEnd) {
            openClosedStatus = [NSString stringWithFormat:@"Open until %@", [self.endTime MITShortTimeOfDayString]];
        }
    }
    
    return openClosedStatus;
}

- (NSDateFormatter *)retailDateFormatter
{
    static NSDateFormatter *mealFormatter;
    if (!mealFormatter) {
        mealFormatter = [[NSDateFormatter alloc] init];
        [mealFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
    }
    return mealFormatter;
}

- (NSDate *)startTime
{
    NSString *dateString = [self.dateString stringByAppendingString:self.startTimeString];
    return [[self retailDateFormatter] dateFromString:dateString];
}

- (NSDate *)endTime
{
    NSString *dateString = [self.dateString stringByAppendingString:self.endTimeString];
    return [[self retailDateFormatter] dateFromString:dateString];
}

- (NSDate *)date
{
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-mm-dd"];
    }
    return [formatter dateFromString:self.dateString];
}

@end
