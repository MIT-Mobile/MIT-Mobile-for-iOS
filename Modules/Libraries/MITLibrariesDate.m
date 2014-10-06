#import "MITLibrariesDate.h"
#import "Foundation+MITAdditions.h"

@interface MITLibrariesDate ()

@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSDate *endDate;

@end

@implementation MITLibrariesDate

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesDate class]];
    
    [mapping addAttributeMappingsFromArray:@[@"start", @"end"]];
    
    return mapping;
}

- (void)setStart:(NSString *)start
{
    _start = start;
    self.startDate = nil;
}

- (void)setEnd:(NSString *)end
{
    _end = end;
    self.endDate = nil;
}

- (NSDate *)startDate
{
    if (!_startDate) {
        [[MITLibrariesDate dateFormatter] setDateFormat:@"yyyy-MM-dd"];
        _startDate = [[MITLibrariesDate dateFormatter] dateFromString:self.start];
    }
    return _startDate;
}

- (NSDate *)endDate
{
    if (!_endDate) {
        [[MITLibrariesDate dateFormatter] setDateFormat:@"yyyy-MM-dd"];
        _endDate = [[MITLibrariesDate dateFormatter] dateFromString:self.end];
    }
    return _endDate;
}

// This assumes that the dates stored are hours only, no day information
- (NSString *)hoursRangesString
{
    NSDateFormatter *dateFormatter = [MITLibrariesDate dateFormatter];

    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // We don't really care what the date is, only the hours of that date (things sometimes go screwy if you trying to dateFromString with just hours)
    NSString *dateDayString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString *startDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.start];
    NSString *endDateString = [NSString stringWithFormat:@"%@ %@", dateDayString, self.end];
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *startDate = [dateFormatter dateFromString:startDateString];
    NSDate *endDate = [dateFormatter dateFromString:endDateString];
    
    return [[NSString stringWithFormat:@"%@-%@", [self smartStringForDate:startDate], [self smartStringForDate:endDate]] lowercaseString];
}

- (NSString *)smartStringForDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [MITLibrariesDate dateFormatter];
    NSCalendar *calendar = [NSCalendar cachedCurrentCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    
    if (dateComponents.hour == 0) {
        return @"midnight";
    }
    else if (dateComponents.hour == 12) {
        return @"noon";
    }
    else {
        if (dateComponents.minute == 0) {
            [dateFormatter setDateFormat:@"ha"];
        }
        else {
            [dateFormatter setDateFormat:@"h:mma"];
        }
        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)dayRangesString
{
    NSDateFormatter *dateFormatter = [MITLibrariesDate dateFormatter];
    
    if ([self.start isEqualToString:self.end]) {
        [dateFormatter setDateFormat:@"MMM d"];
        
        return [[MITLibrariesDate dateFormatter] stringFromDate:self.startDate];
    }
    else {
        
        [dateFormatter  setDateFormat:@"MMM "];
        
        NSString *startingMonth = [dateFormatter stringFromDate:self.startDate];
        NSString *endingMonth = [dateFormatter stringFromDate:self.endDate];
        
        [dateFormatter setDateFormat:@"d"];
        
        NSString *startingDay = [dateFormatter stringFromDate:self.startDate];
        NSString *endingDay = [dateFormatter stringFromDate:self.endDate];
        
        if ([startingMonth isEqualToString:endingMonth]) {
            endingMonth = @"";
        }
        
        return [NSString stringWithFormat:@"%@%@-%@%@", startingMonth, startingDay, endingMonth, endingDay];
    }
}

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return dateFormatter;
}

@end
