#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningHouseDay, MITDiningLocation, MITDiningVenues, MITDiningMeal;

@interface MITDiningHouseVenue : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) id payment;
@property (nonatomic, retain) NSString * shortName;
@property (nonatomic, retain) MITDiningLocation *location;
@property (nonatomic, retain) NSOrderedSet *mealsByDay;
@property (nonatomic, retain) MITDiningVenues *venues;

- (BOOL)isOpenNow;
- (MITDiningHouseDay *)houseDayForDate:(NSDate *)date;
- (NSString *)hoursToday;

- (NSArray *)sortedMealsInWeek;
- (NSArray *)groupedMealTimeSummaries;

@end

@interface MITDiningHouseVenue (CoreDataGeneratedAccessors)

- (void)insertObject:(MITDiningHouseDay *)value inMealsByDayAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMealsByDayAtIndex:(NSUInteger)idx;
- (void)insertMealsByDay:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMealsByDayAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMealsByDayAtIndex:(NSUInteger)idx withObject:(MITDiningHouseDay *)value;
- (void)replaceMealsByDayAtIndexes:(NSIndexSet *)indexes withMealsByDay:(NSArray *)values;
- (void)addMealsByDayObject:(MITDiningHouseDay *)value;
- (void)removeMealsByDayObject:(MITDiningHouseDay *)value;
- (void)addMealsByDay:(NSOrderedSet *)values;
- (void)removeMealsByDay:(NSOrderedSet *)values;

@end
