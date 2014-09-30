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

- (BOOL)isOpenAtDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    
    NSString *dayOfWeekAbbreviation = [date MITDateCode];

    if (![self.days containsString:dayOfWeekAbbreviation]) {
        return NO;
    }
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:date], self.hours.start];
    
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:date], self.hours.end];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSDate *startDate = [dateFormatter dateFromString:startDateString];

    // We can get back 00:00:00 as a time a library shuts, which should actually be midnight of the following day, so we need to adjust for this...
    NSDate *endDate = [dateFormatter dateFromString:endDateString];
    if ([endDate isEqualToDate:[date startOfDay]]) {
        endDate = [endDate dateByAddingDay];
    }
    
    return [date dateFallsBetweenStartDate:startDate endDate:endDate];
}

@end
