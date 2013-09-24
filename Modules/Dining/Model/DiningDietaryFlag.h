#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DiningMealItem;

@interface DiningDietaryFlag : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *items;
@property (nonatomic, readonly, strong) NSString *pdfPath;
@property (nonatomic, readonly, strong) NSString *displayName;

@end

@interface DiningDietaryFlag (CoreDataGeneratedAccessors)

- (void)addItemsObject:(DiningMealItem *)value;
- (void)removeItemsObject:(DiningMealItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

+ (void) createDietaryFlagsInStore;
+ (DiningDietaryFlag *)flagWithName:(NSString *)name;       // creates flag with name if it doesn't exist
+ (NSSet *)flagsWithNames:(NSArray *)flagNames;            // returns flags in persistent store with names in array

@end
