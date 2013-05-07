#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DiningMealItem : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * station;
@property (nonatomic, retain) NSManagedObject *meal;
@property (nonatomic, retain) NSSet *dietaryFlags;

+ (DiningMealItem *)newItemWithDictionary:(NSDictionary *)dict;

@end

@interface DiningMealItem (CoreDataGeneratedAccessors)

- (void)addDietaryFlagsObject:(NSManagedObject *)value;
- (void)removeDietaryFlagsObject:(NSManagedObject *)value;
- (void)addDietaryFlags:(NSSet *)values;
- (void)removeDietaryFlags:(NSSet *)values;

@end
