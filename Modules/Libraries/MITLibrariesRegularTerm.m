#import "MITLibrariesRegularTerm.h"
#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

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
    
    return [self.days containsString:dayOfWeekAbbreviation];
}

- (NSString *)hoursString
{
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    NSString *dateDayString = [self.dateFormatter stringFromDate:[NSDate date]];
    
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.hours.start];
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.hours.end];
    
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *startDate = [self.dateFormatter dateFromString:startDateString];
    NSDate *endDate = [self.dateFormatter dateFromString:endDateString];
    
    [self.dateFormatter setDateFormat:@"h:mma"];
    
    NSString *openString = [self.dateFormatter stringFromDate:startDate];
    NSString *closeString = [endDate isEqualToDate:[endDate startOfDay]] ? @"midnight" : [self.dateFormatter stringFromDate:endDate];
    
    return [[NSString stringWithFormat:@"%@-%@", openString, closeString] lowercaseString];
}

- (NSString *)termHoursDescription
{
    return [NSString stringWithFormat:@"%@ %@", [self termsDayRangeString], [self hoursString]];
}

- (NSString *)termsDayRangeString
{
    NSString *dayRangesString = @"";
    NSNumber *startOfRange = nil;
    NSNumber *endOfRange = nil;
    for (NSNumber *dateCodeNumber in self.sortedDateCodesArray) {
        if (!endOfRange) {
            startOfRange = endOfRange = dateCodeNumber;
        }
        else if ([dateCodeNumber integerValue] == [endOfRange integerValue] + 1) {
            endOfRange = dateCodeNumber;
        }
        else {
            dayRangesString = [self dayRangeStringWithBaseString:dayRangesString startOfRange:startOfRange endOfRange:endOfRange];
            startOfRange = endOfRange = dateCodeNumber;
        }
    }
    if (startOfRange && endOfRange) {
        dayRangesString = [self dayRangeStringWithBaseString:dayRangesString startOfRange:startOfRange endOfRange:endOfRange];
    }
    return dayRangesString;

}

- (NSString *)dayRangeStringWithBaseString:(NSString *)baseString startOfRange:(NSNumber *)startOfRange endOfRange:(NSNumber *)endOfRange
{
    if (baseString.length > 0) {
        baseString = [baseString stringByAppendingString:@", "];
    }
    
    NSString *startingString = self.dateFormatter.weekdaySymbols[[startOfRange integerValue]];
    NSString *endingString = self.dateFormatter.weekdaySymbols[[endOfRange integerValue]];
    
    NSString *rangesString = [startOfRange isEqualToNumber:endOfRange] ? startingString : [NSString stringWithFormat:@"%@-%@", startingString, endingString];
    baseString = [baseString stringByAppendingString:rangesString];
    
    return baseString;
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

@end
