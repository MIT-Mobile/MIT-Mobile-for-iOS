#import "MITLibrariesExceptionsTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

static NSString * const MITLibrariesExceptionTermCodingKeyDates = @"MITLibrariesExceptionTermCodingKeyDates";
static NSString * const MITLibrariesExceptionTermCodingKeyHours = @"MITLibrariesExceptionTermCodingKeyHours";
static NSString * const MITLibrariesExceptionTermCodingKeyReason = @"MITLibrariesExceptionTermCodingKeyReason";

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

- (NSString *)termHoursDescription
{
    return [NSString stringWithFormat:@"%@ %@ (%@)", [self.dates dayRangesString], [self.hours hoursRangesString], self.reason];
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return dateFormatter;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.dates = [aDecoder decodeObjectForKey:MITLibrariesExceptionTermCodingKeyDates];
        self.hours = [aDecoder decodeObjectForKey:MITLibrariesExceptionTermCodingKeyHours];
        self.reason = [aDecoder decodeObjectForKey:MITLibrariesExceptionTermCodingKeyReason];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dates forKey:MITLibrariesExceptionTermCodingKeyDates];
    [aCoder encodeObject:self.hours forKey:MITLibrariesExceptionTermCodingKeyHours];
    [aCoder encodeObject:self.reason forKey:MITLibrariesExceptionTermCodingKeyReason];
}

@end
