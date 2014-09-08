#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningHouseDay, MITDiningMenuItem;

@interface MITDiningMeal : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString *endTimeString;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *startTimeString;
@property (nonatomic, retain) MITDiningHouseDay *houseDay;
@property (nonatomic, retain) NSOrderedSet *items;

- (NSDate *)startTime;
- (NSDate *)endTime;

- (NSString *)mealHoursDescription;
- (NSString *)nameAndHoursDescription;
- (BOOL)isSuperficiallyEqualToMeal:(MITDiningMeal *)meal;
- (NSString *)titleCaseName;

@end

@interface MITDiningMeal (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningMenuItem *)value inItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromItemsAtIndex:(NSUInteger)idx;
- (void)insertItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInItemsAtIndex:(NSUInteger)idx withObject:(MITDiningMenuItem *)value;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray *)values;
- (void)addItemsObject:(MITDiningMenuItem *)value;
- (void)removeItemsObject:(MITDiningMenuItem *)value;
- (void)addItems:(NSOrderedSet *)values;
- (void)removeItems:(NSOrderedSet *)values;

@end
