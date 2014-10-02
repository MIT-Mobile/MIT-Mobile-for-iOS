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
    return [NSString stringWithFormat:@"%@ Closed (%@)", [self.dates dayRangesString], self.reason];
}

- (BOOL)isClosedOnDate:(NSDate *)date
{
    return ([date dateFallsBetweenStartDate:self.dates.startDate endDate:self.dates.endDate]);
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
