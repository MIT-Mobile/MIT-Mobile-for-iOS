#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"
#import "MITCalendarsContact.h"
#import "MITCalendarsLocation.h"

@class MITCalendarsSeriesInfo, MITCalendarsSponsor, MITCalendarsCalendar, EKEvent;

@interface MITCalendarsEvent : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSDate *startAt;
@property (nonatomic, retain) NSDate *endAt;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *htmlDescription;
@property (nonatomic, retain) NSString *tickets;
@property (nonatomic, retain) NSString *cost;
@property (nonatomic, retain) NSString *openTo;
@property (nonatomic, retain) NSString *ownerID;
@property (nonatomic, retain) NSString *lecturer;
@property (nonatomic, retain) NSNumber *cancelled;
@property (nonatomic, retain) NSString *typeCode;
@property (nonatomic, retain) NSString *statusCode;
@property (nonatomic, retain) NSString *createdBy;
@property (nonatomic, retain) NSDate *createdAt;
@property (nonatomic, retain) NSString *modifiedBy;
@property (nonatomic, retain) NSDate *modifiedAt;
@property (nonatomic, retain) MITCalendarsLocation *location;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) NSSet *sponsors;
@property (nonatomic, retain) MITCalendarsContact *contact;
@property (nonatomic, retain) MITCalendarsSeriesInfo *seriesInfo;

- (NSString *)dateStringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle separator:(NSString *)separator;
- (void)setUpEKEvent:(EKEvent *)ekEvent;
- (BOOL)isHoliday;

@end

@interface MITCalendarsEvent (CoreDataGeneratedAccessors)

- (void)insertObject:(MITCalendarsCalendar *)value inCategoriesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCategoriesAtIndex:(NSUInteger)idx;
- (void)insertCategories:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCategoriesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCategoriesAtIndex:(NSUInteger)idx withObject:(MITCalendarsCalendar *)value;
- (void)replaceCategoriesAtIndexes:(NSIndexSet *)indexes withCategories:(NSArray *)values;
- (void)addCategoriesObject:(MITCalendarsCalendar *)value;
- (void)removeCategoriesObject:(MITCalendarsCalendar *)value;
- (void)addCategories:(NSOrderedSet *)values;
- (void)removeCategories:(NSOrderedSet *)values;
- (void)addSponsorsObject:(MITCalendarsSponsor *)value;
- (void)removeSponsorsObject:(MITCalendarsSponsor *)value;
- (void)addSponsors:(NSSet *)values;
- (void)removeSponsors:(NSSet *)values;

@end