#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsCalendar, MITCalendarsEvent;

@interface MITCalendarsCalendar : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * eventsUrl;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) NSOrderedSet *parentCategory;
@property (nonatomic, retain) NSSet *events;

@property (nonatomic, readonly) BOOL hasSubCategories;
- (BOOL)isEqualToCalendar:(MITCalendarsCalendar *)calendar;

@end

@interface MITCalendarsCalendar (CoreDataGeneratedAccessors)

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
- (void)insertObject:(MITCalendarsCalendar *)value inParentCategoryAtIndex:(NSUInteger)idx;
- (void)removeObjectFromParentCategoryAtIndex:(NSUInteger)idx;
- (void)insertParentCategory:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeParentCategoryAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInParentCategoryAtIndex:(NSUInteger)idx withObject:(MITCalendarsCalendar *)value;
- (void)replaceParentCategoryAtIndexes:(NSIndexSet *)indexes withParentCategory:(NSArray *)values;
- (void)addParentCategoryObject:(MITCalendarsCalendar *)value;
- (void)removeParentCategoryObject:(MITCalendarsCalendar *)value;
- (void)addParentCategory:(NSOrderedSet *)values;
- (void)removeParentCategory:(NSOrderedSet *)values;
- (void)addEventsObject:(MITCalendarsEvent *)value;
- (void)removeEventsObject:(MITCalendarsEvent *)value;
- (void)addEvents:(NSSet *)values;
- (void)removeEvents:(NSSet *)values;

@end