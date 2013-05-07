#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiningDay, DiningMealItem;

@interface DiningMeal : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) DiningDay *day;
@property (nonatomic, retain) NSOrderedSet *items;

+ (DiningMeal *)newMealWithDictionary:(NSDictionary* )dict;

@end

@interface DiningMeal (CoreDataGeneratedAccessors)

- (void)addItemsObject:(DiningMealItem *)value;
- (void)removeItemsObject:(DiningMealItem *)value;
- (void)addItems:(NSOrderedSet *)values;
- (void)removeItems:(NSOrderedSet *)values;

@end
