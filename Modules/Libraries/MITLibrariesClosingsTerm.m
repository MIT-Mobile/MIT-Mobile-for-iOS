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

- (BOOL)isClosedOnDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    
    NSDate *startDate = [dateFormatter dateFromString:self.dates.start];
    NSDate *endDate = [dateFormatter dateFromString:self.dates.end];
    
    return ([date dateFallsBetweenStartDate:startDate endDate:endDate]);
}

@end
