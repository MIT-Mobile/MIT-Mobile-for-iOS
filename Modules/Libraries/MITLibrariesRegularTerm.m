#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

static NSString * const MITLibrariesRegularTermCodingKeyDays = @"MITLibrariesRegularTermCodingKeyDays";
static NSString * const MITLibrariesRegularTermCodingKeyHours = @"MITLibrariesRegularTermCodingKeyHours";

@interface MITLibrariesRegularTerm ()

@property (nonatomic, strong) NSArray *sortedDateCodesArray;

@end

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
    
    return ([self.days rangeOfString:dayOfWeekAbbreviation].location != NSNotFound);
}

- (NSString *)termHoursDescription
{
    return [NSString stringWithFormat:@"%@ %@", [self termsDayRangeString], [self.hours hoursRangesString]];
}

- (NSString *)termsDayRangeString
{
    NSMutableArray *dayRanges = [[NSMutableArray alloc] init];
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];

    [self.sortedDateCodesArray enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
        [indexSet addIndex:[number unsignedIntegerValue]];
    }];

    [indexSet enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        NSInteger startWeekdaySymbolIndex = range.location;
        NSInteger endWeekdaySymbolIndex = range.location + (range.length - 1); // Decrement length by 1 to account for 0 indexing

        NSString *rangeString = [self dayRangeStringFromWeekdaySymbolIndex:startWeekdaySymbolIndex toWeekdaySymbolIndex:endWeekdaySymbolIndex];
        [dayRanges addObject:rangeString];
    }];

    return [dayRanges componentsJoinedByString:@", "];
}

- (NSString *)dayRangeStringFromWeekdaySymbolIndex:(NSInteger)startWeekdaySymbol toWeekdaySymbolIndex:(NSInteger)endWeekdaySymbol
{
    NSAssert(startWeekdaySymbol <= endWeekdaySymbol, @"The week cannot start before it ends!");
    
    NSMutableString *rangeString = [[NSMutableString alloc] init];
    NSArray *weekdaySymbols = self.dateFormatter.weekdaySymbols;
    
    if (startWeekdaySymbol == endWeekdaySymbol) {
        [rangeString appendString:weekdaySymbols[startWeekdaySymbol]];
    } else {
        [rangeString appendFormat:@"%@-%@",weekdaySymbols[startWeekdaySymbol],weekdaySymbols[endWeekdaySymbol]];
    }
    
    NSAssert(rangeString.length, @"invalid day range");
    return rangeString;
}

- (NSArray *)sortedDateCodesArray
{
    if (!_sortedDateCodesArray) {
        NSMutableArray *dateCodes = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.days.length; i++) {
            NSString *dateCode = [self.days substringWithRange:NSMakeRange(i, 1)];
            [dateCodes addObject:[NSDate numberForDateCode:dateCode]];
        }
        
        [dateCodes sortUsingSelector:@selector(compare:)];
        _sortedDateCodesArray = dateCodes;
    }
    return _sortedDateCodesArray;
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
        self.days = [aDecoder decodeObjectForKey:MITLibrariesRegularTermCodingKeyDays];
        self.hours = [aDecoder decodeObjectForKey:MITLibrariesRegularTermCodingKeyHours];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.days forKey:MITLibrariesRegularTermCodingKeyDays];
    [aCoder encodeObject:self.hours forKey:MITLibrariesRegularTermCodingKeyHours];
}

@end
