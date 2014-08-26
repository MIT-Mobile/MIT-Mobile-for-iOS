#import "MITDiningRetailDay.h"
#import "MITDiningRetailVenue.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningRetailDay

@dynamic date;
@dynamic endTime;
@dynamic message;
@dynamic startTime;
@dynamic retailHours;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"start_time" : @"startTime",
                                                  @"end_time" : @"endTime"}];
    [mapping addAttributeMappingsFromArray:@[@"date", @"message"]];
    
    return mapping;
}

#pragma mark - Convenience Methods

- (NSString *)hoursSummary
{
    NSString *hoursSummary = nil;
    
    if (self.message) {
        hoursSummary = self.message;
    } else if (self.startTime && self.endTime) {
        NSString *startString = [self.startTime MITShortTimeOfDayString];
        NSString *endString = [self.endTime MITShortTimeOfDayString];
        
        hoursSummary = [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    } else {
        hoursSummary = @"Closed for the day";
    }
    
    return hoursSummary;
}

#pragma mark - Open/Closed Status

- (NSString *)openClosedStatusRelativeToDate:(NSDate *)date
{
    NSString *openClosedStatus = @"Closed for the day";
    if (self.message) {
        openClosedStatus = self.message;
    } else {
        NSTimeInterval dateInterval = [date timeIntervalSince1970];
        NSTimeInterval bestMealStart = [self.startTime timeIntervalSince1970];
        NSTimeInterval bestMealEnd = [self.endTime timeIntervalSince1970];
        
        if (dateInterval < bestMealStart) {
            openClosedStatus = [NSString stringWithFormat:@"Opens at %@", [self.startTime MITShortTimeOfDayString]];
        } else if (dateInterval < bestMealEnd) {
            openClosedStatus = [NSString stringWithFormat:@"Open until %@", [self.endTime MITShortTimeOfDayString]];
        }
    }
    
    return openClosedStatus;
}

@end
