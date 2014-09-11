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

- (NSString *)statusStringForDate:(NSDate *)date
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

+ (NSDateFormatter *)retailDateFormatter
{
    static NSDateFormatter *retailFormatter;
    if (!retailFormatter) {
        retailFormatter = [[NSDateFormatter alloc] init];
        [retailFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
    }
    return retailFormatter;
}

+ (NSDateFormatter *)dayOnlyFormatter
{
    static NSDateFormatter *dayFormatter;
    if (!dayFormatter) {
        dayFormatter = [[NSDateFormatter alloc] init];
        [dayFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return dayFormatter;
}

- (NSDate *)startTime
{
    NSString *dateString = [NSString stringWithFormat:@"%@ %@", self.dateString, self.startTimeString];
    return [[MITDiningRetailDay retailDateFormatter] dateFromString:dateString];
}

- (NSDate *)endTime
{
    NSString *dateString = [NSString stringWithFormat:@"%@ %@", self.dateString, self.endTimeString];
    return [[MITDiningRetailDay retailDateFormatter] dateFromString:dateString];
}

- (NSDate *)date
{
    return [[MITDiningRetailDay dayOnlyFormatter] dateFromString:self.dateString];
}

@end
