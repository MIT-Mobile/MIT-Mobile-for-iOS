#import "MITCalendarEventDateParser.h"
#import "MITCalendarsEvent.h"
#import "Foundation+MITAdditions.h"

@implementation MITCalendarEventDateParser

+ (NSArray *)getSortedDatesForEvents:(NSArray *)events {
    if (events.count == 0 || !events) {
        return nil;
    }
    
    NSMutableSet *uniqueDates = [NSMutableSet setWithCapacity:(events.count / 2)];
    for (MITCalendarsEvent *event in events) {
        [uniqueDates addObject:[event.startAt dateWithoutTime]];
    }
    
    NSArray *sortedArray = [[uniqueDates allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    return sortedArray;
}

+ (NSDictionary *)getDateKeyedDictionaryForEvents:(NSArray *)events {
    if (!events || events.count == 0) {
        return nil;
    }
    
    NSArray *dates = [self getSortedDatesForEvents:events];
    
    NSMutableDictionary *dateKeyedEvents = [NSMutableDictionary dictionaryWithCapacity:[dates count]];
    
    for (NSDate *date in dates) {
        NSMutableArray *currentDateEvents = [NSMutableArray array];
        
        for (MITCalendarsEvent *event in events) {
            if ([[event.startAt dateWithoutTime] isEqualToDate:date]) {
                [currentDateEvents addObject:event];
            }
        }
        
        [dateKeyedEvents setObject:[NSArray arrayWithArray:currentDateEvents] forKey:date];
    }
    
    return [NSDictionary dictionaryWithDictionary:dateKeyedEvents];
}

@end
