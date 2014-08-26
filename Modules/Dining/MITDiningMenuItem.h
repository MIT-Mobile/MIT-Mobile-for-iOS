#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITDiningMeal;

@interface MITDiningMenuItem : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) id dietaryFlags;
@property (nonatomic, retain) NSString * itemDescription;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * station;
@property (nonatomic, retain) NSSet *meal;
@end

@interface MITDiningMenuItem (CoreDataGeneratedAccessors)

- (void)addMealObject:(MITDiningMeal *)value;
- (void)removeMealObject:(MITDiningMeal *)value;
- (void)addMeal:(NSSet *)values;
- (void)removeMeal:(NSSet *)values;

+ (NSString *)pdfNameForDietaryFlag:(NSString *)flag;
+ (NSString *)displayNameForDietaryFlag:(NSString *)flag;

@end
