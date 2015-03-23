#import "MITLibrariesClosingsTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

static NSString * const MITLibrariesClosingTermCodingKeyDates = @"MITLibrariesClosingTermCodingKeyDates";
static NSString * const MITLibrariesClosingTermCodingKeyReason = @"MITLibrariesClosingTermCodingKeyReason";

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
    return ([date dateFallsBetweenStartDate:self.dates.startDate endDate:self.dates.endDate components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)]);
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.dates = [aDecoder decodeObjectForKey:MITLibrariesClosingTermCodingKeyDates];
        self.reason = [aDecoder decodeObjectForKey:MITLibrariesClosingTermCodingKeyReason];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dates forKey:MITLibrariesClosingTermCodingKeyDates];
    [aCoder encodeObject:self.reason forKey:MITLibrariesClosingTermCodingKeyReason];
}

@end
