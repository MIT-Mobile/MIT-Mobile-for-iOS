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
    NSMutableString *dayRangeString = [[NSMutableString alloc] init];
    NSNumber *startOfRange = nil;
    NSNumber *endOfRange = nil;
    
    for (NSNumber *currentWeekdaySymbolNumber in self.sortedDateCodesArray) {
        if (!startOfRange) {
            // If startOfRangeis nil, we have not looped through yet or we
            // are at the beginning of a new subset.
            // Set the start and end dates to the same day and continue on.
            startOfRange = currentWeekdaySymbolNumber;
            endOfRange = currentWeekdaySymbolNumber;
        } else {
            NSInteger currentWeekdaySymbolIndex = [currentWeekdaySymbolNumber integerValue];
            NSInteger startWeekdaySymbolIndex = [startOfRange integerValue];
            NSInteger endWeekdaySymbolIndex = [endOfRange integerValue];
            
            // This check assumes self.sortedDateCodesArray is sorted in ascending order.
            if ((currentWeekdaySymbolIndex - endWeekdaySymbolIndex) <= 1) {
                // The current weekday number is either the same
                // or immediately adjacent to the previous weekday. Move the end
                // of range value and continue on in the loop
                endOfRange = currentWeekdaySymbolNumber;
            } else {
                // If the current weekday isn't the immediate next day,
                // append the new day range into the result string, clear the
                // array of matching ranges and keep going.
                NSString *rangeString = [self dayRangeStringFromWeekdaySymbolIndex:startWeekdaySymbolIndex toWeekdaySymbolIndex:endWeekdaySymbolIndex];
                
                if (dayRangeString.length) {
                    [dayRangeString appendFormat:@", %@",rangeString];
                } else {
                    [dayRangeString appendString:rangeString];
                }
                
                startOfRange = nil;
                endOfRange = nil;
            }
        }
    }
    
    if (!dayRangeString.length) {
        // If we get to this point the dayRangeString was not generated because
        // the weekday symbol indexes in sortedDateCodesArray are a single
        // contiguous block.
        NSInteger startWeekday = [startOfRange integerValue];
        NSInteger endWeekday = [endOfRange integerValue];
        
        [dayRangeString appendString:[self dayRangeStringFromWeekdaySymbolIndex:startWeekday toWeekdaySymbolIndex:endWeekday]];
    }
    
    return dayRangeString;
}

- (NSString *)dayRangeStringFromWeekdaySymbolIndex:(NSInteger)startWeekdaySymbol toWeekdaySymbolIndex:(NSInteger)endWeekdaySymbol
{
    NSAssert(startWeekdaySymbol <= endWeekdaySymbol, @"The week cannot start before it ends!");
    
    NSMutableString *rangeString = [[NSMutableString alloc] init];

    // Increment the length of the range by 1 because the range should be
    // inclusive of the ending day.
    NSRange weekdayRange = NSMakeRange(startWeekdaySymbol, (endWeekdaySymbol - startWeekdaySymbol) + 1);
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:weekdayRange];
    NSArray *weekdays = [self.dateFormatter.weekdaySymbols objectsAtIndexes:indexes];
    
    if (weekdayRange.length == 1) {
        [rangeString appendString:[weekdays firstObject]];
    } else {
        [rangeString appendFormat:@"%@-%@",[weekdays firstObject],[weekdays lastObject]];
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
