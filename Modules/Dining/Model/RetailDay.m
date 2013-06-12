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
        day.startTime = [day.date dateWithTimeOfDayFromDate:date];
    }
    
    if (dict[@"end_time"]) {
        NSDate *date = [formatter dateFromString:dict[@"end_time"]];
        day.endTime = [day.date dateWithTimeOfDayFromDate:date];;
    }
    
    return day;
}

- (NSString *)hoursSummary {
    
    if (self.message) {
        return self.message;
    }
    
    if (self.startTime && self.endTime) {
        NSString *startString = [self.startTime MITShortTimeOfDayString];
        NSString *endString = [self.endTime MITShortTimeOfDayString];
        
        return [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    }
    return @"Closed for the day";
}

- (NSString *)statusStringRelativeToDate:(NSDate *)date {
    //      Returns hall status relative to the curent time of day.
    //      Example return strings
    //          - Closed for the day
    //          - Opens at 5:30pm
    //          - Open until 4pm
    
    // If there's a message, it wins.
    // This is important for places like La Verde's which list their hours as "Open 24 Hours".
    if (self.message) {
        return self.message;
    }
    
    if (self.startTime && self.endTime) {
        // need to calculate if the current time is before opening, before closing, or after closing
        BOOL isBeforeStart = ([self.startTime compare:date] == NSOrderedDescending);
        BOOL isBeforeEnd   = ([self.endTime compare:date] == NSOrderedDescending);
        
        if (isBeforeStart) {
            // now-start-end
            return [NSString stringWithFormat:@"Opens at %@", [self.startTime MITShortTimeOfDayString]];
        } else if (isBeforeEnd) {
            // start-now-end
            return [NSString stringWithFormat:@"Open until %@", [self.endTime MITShortTimeOfDayString]];
        }
    }
    
    // start-end-now or ?-now-?
    
    // if there's no hours today
    return @"Closed for the day";
}

@end
