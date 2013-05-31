#import "RetailDay.h"
#import "RetailVenue.h"
#import "CoreDataManager.h"
#import "Foundation+MITAdditions.h"

@implementation RetailDay

@dynamic date;
@dynamic startTime;
@dynamic endTime;
@dynamic message;
@dynamic venue;

+ (RetailDay *)newDayWithDictionary:(NSDictionary* )dict {
    RetailDay *day = [CoreDataManager insertNewObjectForEntityForName:@"RetailDay"];
    
    // TODO: maybe make an -[NSDate dateForISO8601String:] category
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    NSDate *date = [formatter dateFromString:dict[@"date"]];
    day.date = date;

    if (dict[@"message"]) {
        day.message = dict[@"message"];
    }
    
    // TODO: maybe make an -[NSDate dateForISO8601TimeString:] category
    // Also, make it support both HH:mm and HH:mm:ss, since both are valid time strings
    [formatter setDateFormat:@"HH:mm:ss"];

    
    if (dict[@"start_time"]) {
        NSDate *date = [formatter dateFromString:dict[@"start_time"]];
        day.startTime = [day.date dateByAdjustingToTimeFromDate:date];
    }
    
    if (dict[@"end_time"]) {
        NSDate *date = [formatter dateFromString:dict[@"end_time"]];
        day.endTime = [day.date dateByAdjustingToTimeFromDate:date];;
    }
    
    return day;
}

- (NSString *)hoursSummary {
    
    if (!self.startTime || !self.endTime) {
        return self.message;
    }
    
    NSString *startString = [self.startTime MITShortTimeOfDayString];
    NSString *endString = [self.endTime MITShortTimeOfDayString];
    
    return [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
}

@end
