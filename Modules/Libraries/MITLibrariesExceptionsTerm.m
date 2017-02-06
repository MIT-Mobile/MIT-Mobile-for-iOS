#import "MITLibrariesExceptionsTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

static NSString * const MITLibrariesExceptionTermCodingKeyDates = @"MITLibrariesExceptionTermCodingKeyDates";
static NSString * const MITLibrariesExceptionTermCodingKeyHours = @"MITLibrariesExceptionTermCodingKeyHours";
static NSString * const MITLibrariesExceptionTermCodingKeyReason = @"MITLibrariesExceptionTermCodingKeyReason";

@interface MITLibrariesExceptionsTerm ()
@property(nonatomic,readonly,strong) NSDate *startDate;
@property(nonatomic,readonly,strong) NSDate *endDate;
@end

@implementation MITLibrariesExceptionsTerm
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;

+ (NSDateFormatter*)dateTimeFormatter
{
    static NSDateFormatter *dateTimeFormatter = nil;
    static dispatch_once_t dateTimeFormatterToken;
    dispatch_once(&dateTimeFormatterToken, ^{
        dateTimeFormatter = [[NSDateFormatter alloc] init];
        dateTimeFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    });
    
    return dateTimeFormatter;
}

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
    NSDate *endDate = self.endDate;
    if ([endDate isEqualToDate:[date startOfDay]]) {
        endDate = [endDate dateByAddingDay];
    }
    
    return ([date dateFallsBetweenStartDate:self.startDate endDate:endDate]);
}

- (BOOL)isOpenOnDayOfDate:(NSDate *)date
{
    return [date dateFallsBetweenStartDate:self.startDate endDate:self.endDate components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)];
}

- (NSDate*)startDate
{
    if (!_startDate) {
        NSString *startDateString = [NSString stringWithFormat:@"%@ %@", self.dates.start, self.hours.start];
        _startDate = [[MITLibrariesExceptionsTerm dateTimeFormatter] dateFromString:startDateString];
    }
    
    return _startDate;
}

- (NSDate*)endDate
{
    if (!_endDate) {
        NSString *startDateString = [NSString stringWithFormat:@"%@ %@", self.dates.end, self.hours.end];
        _endDate = [[MITLibrariesExceptionsTerm dateTimeFormatter] dateFromString:startDateString];
    }
    
    return _endDate;
}

- (NSString *)termHoursDescription
{
    return [NSString stringWithFormat:@"%@ %@ (%@)", [self.dates dayRangesString], [self.hours hoursRangesString], self.reason];
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
