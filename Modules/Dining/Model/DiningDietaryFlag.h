#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiningMealItem;

@interface DiningDietaryFlag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *items;
@end

@interface DiningDietaryFlag (CoreDataGeneratedAccessors)

- (void)addItemsObject:(DiningMealItem *)value;
- (void)removeItemsObject:(DiningMealItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

+ (DiningDietaryFlag *)flagWithName:(NSString *)name;

@end
