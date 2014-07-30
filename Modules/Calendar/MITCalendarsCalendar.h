#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITCalendarsCalendar;

@interface MITCalendarsCalendar : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * eventsUrl;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) NSOrderedSet *categories;
@property (nonatomic, retain) MITCalendarsCalendar *parentCategory;
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
@end
