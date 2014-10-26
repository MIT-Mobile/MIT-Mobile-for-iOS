#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningHouseVenue, MITDiningMeal, MITDiningMealSummary;

@interface MITDiningHouseDay : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * dateString;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) MITDiningHouseVenue *houseVenue;
@property (nonatomic, retain) NSOrderedSet *meals;

+ (NSArray *)mealNames;

- (NSDate *)date;
- (NSString *)dayHoursDescription;
- (MITDiningMeal *)mealWithName:(NSString *)name;
- (MITDiningMeal *)mealForDate:(NSDate *)date;
- (MITDiningMeal *)bestMealForDate:(NSDate *)date;
- (NSString *)statusStringForDate:(NSDate *)date;

- (NSArray *)sortedMealsArray;

- (MITDiningMeal *)firstMealInDay;
- (MITDiningMeal *)lastMealInDay;

- (MITDiningMealSummary *)mealSummaryForDay;

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
