#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

@implementation MITLibrariesRegularTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesRegularTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"days"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"hours" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

- (BOOL)isOpenOnDate:(NSDate *)date
{
    if (![self isOpenOnDayOfDate:date]) {
        return NO;
    }
    
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", [self.dateFormatter stringFromDate:date], self.hours.start];
    
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", [self.dateFormatter stringFromDate:date], self.hours.end];
    
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSDate *startDate = [self.dateFormatter dateFromString:startDateString];

    // We can get back 00:00:00 as a time a library shuts, which should actually be midnight of the following day, so we need to adjust for this...
    NSDate *endDate = [self.dateFormatter dateFromString:endDateString];
    if ([endDate isEqualToDate:[date startOfDay]]) {
        endDate = [endDate dateByAddingDay];
    }
    
    return [date dateFallsBetweenStartDate:startDate endDate:endDate];
}

- (BOOL)isOpenOnDayOfDate:(NSDate *)date
{
    NSString *dayOfWeekAbbreviation = [date MITDateCode];
    
    return [self.days containsString:dayOfWeekAbbreviation];
}

- (NSString *)hoursString
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSString *dateDayString = [self.dateFormatter stringFromDate:[NSDate date]];
    
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.hours.start];
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.hours.end];
    
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *startDate = [self.dateFormatter dateFromString:startDateString];
    NSDate *endDate = [self.dateFormatter dateFromString:endDateString];
    
    [self.dateFormatter setDateFormat:@"h:mma"];
    
    NSString *openString = [self.dateFormatter stringFromDate:startDate];
    NSString *closeString = [endDate isEqualToDate:[endDate startOfDay]] ? @"midnight" : [self.dateFormatter stringFromDate:endDate];
    
    return [NSString stringWithFormat:@"%@-%@", openString, closeString];
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return dateFormatter;
}

@end
