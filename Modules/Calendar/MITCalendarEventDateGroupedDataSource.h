#import <Foundation/Foundation.h>

@class MITCalendarsEvent;

@interface MITCalendarEventDateGroupedDataSource : NSObject

@property (strong, nonatomic) NSArray *eventDates;
@property (strong, nonatomic) NSArray *events;
@property (strong, nonatomic) NSDictionary *eventsByDate;

- (id)initWithEvents:(NSArray *)events;
- (void)replaceAllEvents:(NSArray *)events;
- (void)addEvents:(NSArray *)events;

- (NSDate *)dateForSection:(NSInteger)section;
- (NSInteger)weekdayForSection:(NSInteger)section;
- (NSArray *)eventsForDate:(NSDate *)date;
- (NSInteger)sectionBeginningAtDate:(NSDate *)date;

- (NSArray *)allSections;
- (NSArray *)eventsInSection:(NSUInteger)section;
- (MITCalendarsEvent *)eventForIndex:(NSUInteger)index;
- (MITCalendarsEvent *)eventForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForEvent:(MITCalendarsEvent *)event;
- (NSString *)headerForSection:(NSUInteger)section;

@end
