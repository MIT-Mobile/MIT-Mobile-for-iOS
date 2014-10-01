#import "MITLibrariesClosingsTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

@implementation MITLibrariesClosingsTerm

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesClosingsTerm class]];
    
    [mapping addAttributeMappingsFromArray:@[@"reason"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"dates" mapping:[MITLibrariesDate objectMapping]];
    
    return mapping;
}

- (NSString *)termHoursDescription
{
    return [NSString stringWithFormat:@"%@ Closed (%@)", [self hoursRangesString], self.reason];
}

- (NSString *)hoursRangesString
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [self.dateFormatter dateFromString:self.dates.end];
    
    if ([self.dates.start isEqualToString:self.dates.end]) {
        [self.dateFormatter setDateFormat:@"MMM d"];
        
        return [self.dateFormatter stringFromDate:startDate];
    }
    else {
        
        [self.dateFormatter setDateFormat:@"MMM "];
        
        NSString *startingMonth = [self.dateFormatter stringFromDate:startDate];
        NSString *endingMonth = [self.dateFormatter stringFromDate:endDate];
        
        [self.dateFormatter setDateFormat:@"d"];
        
        NSString *startingDay = [self.dateFormatter stringFromDate:startDate];
        NSString *endingDay = [self.dateFormatter stringFromDate:endDate];
        
        if ([startingMonth isEqualToString:endingMonth]) {
            endingMonth = @"";
        }
        
        return [NSString stringWithFormat:@"%@%@-%@%@", startingMonth, startingDay, endingMonth, endingDay];
    }
}

- (BOOL)isClosedOnDate:(NSDate *)date
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSDate *startDate = [self.dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [self.dateFormatter dateFromString:self.dates.end];
    
    return ([date dateFallsBetweenStartDate:startDate endDate:endDate]);
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
