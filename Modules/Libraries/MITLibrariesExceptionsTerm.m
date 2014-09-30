#import "MITLibrariesExceptionsTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

@implementation MITLibrariesExceptionsTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesExceptionsTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"reason"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"hours" mapping:[MITLibrariesDate objectMapping]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"dates" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

- (BOOL)isOpenOnDate:(NSDate *)date
{
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", self.dates.start, self.hours.start];
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", self.dates.end, self.hours.end];
    
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSDate *startDate = [self.dateFormatter dateFromString:startDateString];
    
    NSDate *endDate = [self.dateFormatter dateFromString:endDateString];
    if ([endDate isEqualToDate:[date startOfDay]]) {
        endDate = [endDate dateByAddingDay];
    }
    
    return ([date dateFallsBetweenStartDate:startDate endDate:endDate]);
}

- (BOOL)isOpenOnDayOfDate:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    
    return [date isEqualToDateIgnoringTime:startDate];
}

- (NSString *)hoursString
{
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", self.dates.start, self.hours.start];
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", self.dates.end, self.hours.end];

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
