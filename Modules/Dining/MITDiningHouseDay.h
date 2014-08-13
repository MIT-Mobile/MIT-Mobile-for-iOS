#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningMeal;

@interface MITDiningHouseDay : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSOrderedSet *meals;
@end

@interface MITDiningHouseDay (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningMeal *)value inMealsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMealsAtIndex:(NSUInteger)idx;
- (void)insertMeals:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMealsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMealsAtIndex:(NSUInteger)idx withObject:(MITDiningMeal *)value;
- (void)replaceMealsAtIndexes:(NSIndexSet *)indexes withMeals:(NSArray *)values;
- (void)addMealsObject:(MITDiningMeal *)value;
- (void)removeMealsObject:(MITDiningMeal *)value;
- (void)addMeals:(NSOrderedSet *)values;
- (void)removeMeals:(NSOrderedSet *)values;
@end
