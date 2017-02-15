#import "MITCalendarEventDateGroupedDataSource.h"
#import "MITCalendarEventDateParser.h"
#import "MITCalendarsEvent.h"
#import "Foundation+MITAdditions.h"

@interface MITCalendarEventDateGroupedDataSource ()

@end

@implementation MITCalendarEventDateGroupedDataSource

- (id)initWithEvents:(NSArray *)events {
    if (self = [super init]) {
        [self parseEvents:events];
    }
    
    return self;
}

- (void)parseEvents:(NSArray *)events {
    if (events && events.count > 0) {
        self.events = events;
        self.eventDates = [MITCalendarEventDateParser getSortedDatesForEvents:events];
        self.eventsByDate = [MITCalendarEventDateParser getDateKeyedDictionaryForEvents:events];
    } else {
        self.events = nil;
        self.eventDates = nil;
        self.eventsByDate = nil;
    }
}

- (void)replaceAllEvents:(NSArray *)events {
    [self parseEvents:events];
}

- (void)addEvents:(NSArray *)events {
    NSArray *newEvents = [self.events arrayByAddingObjectsFromArray:events];
    [self parseEvents:newEvents];
}

- (NSDate *)dateForSection:(NSInteger)section {
    return [self.eventDates objectAtIndex:section];
}

- (NSInteger)weekdayForSection:(NSInteger)section {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[self dateForSection:section]];
    return components.weekday;
}

- (NSArray *)eventsForDate:(NSDate *)date {
    NSArray *events = nil;
    
    date = [date dateWithoutTime];
    for (NSDate *storedDate in self.eventDates) {
        if ([date compare:storedDate] == NSOrderedSame) {
            events = [self.eventsByDate objectForKey:storedDate];
        }
    }
    
    return events;
}

- (NSInteger)sectionBeginningAtDate:(NSDate *)date
{
    NSInteger sectionIndex = 0;
    for (int i = 0; i < self.eventDates.count; i++) {
        if ([date isEqualToDateIgnoringTime:self.eventDates[i]]) {
            sectionIndex = i;
            break;
        } else if ([date compare:self.eventDates[i]] == NSOrderedAscending) {
            sectionIndex = i;
            break;
        }
    }
    
    return sectionIndex;
}


- (NSArray *)allSections
{
    return self.eventDates;
}

- (NSArray *)eventsInSection:(NSUInteger)section
{
    if (section < self.eventDates.count) {
        id key = [self.eventDates objectAtIndex:section];
        return [self.eventsByDate objectForKey:key];
    }
    return nil;
}

- (MITCalendarsEvent *)eventForIndex:(NSUInteger)index
{
    if (index < self.events.count) {
        return [self.events objectAtIndex:index];
    }
    return nil;
}

- (MITCalendarsEvent *)eventForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *eventsInSection = [self eventsInSection:indexPath.section];
    if (indexPath.row < eventsInSection.count) {
        return eventsInSection[indexPath.row];
    }
    return nil;
}

- (NSIndexPath *)indexPathForEvent:(MITCalendarsEvent *)event
{
    NSUInteger section = [self.eventDates indexOfObject:event.startAt];
    NSUInteger row = [[self.eventsByDate objectForKey:event.startAt] indexOfObject:event];
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSString *)headerForSection:(NSUInteger)section
{
    static NSDateFormatter *eventDateFormatter = nil;
    
    if (!eventDateFormatter) {
        eventDateFormatter = [[NSDateFormatter alloc] init];
        NSString *localizedDateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEE, MMMM dd" options:0 locale:[NSLocale currentLocale]];
        eventDateFormatter.dateFormat = localizedDateFormat;
    }
    
    NSDate *date = [self.eventDates objectAtIndex:section];
    return [eventDateFormatter stringFromDate:date];
}

@end
