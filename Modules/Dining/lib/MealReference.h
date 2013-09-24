
#import <Foundation/Foundation.h>
#import "DiningMeal.h"

extern NSString * const MealReferenceEmptyMeal; // Empty Meal

@interface MealReference : NSObject

@property (nonatomic, strong) NSString  * name;
@property (nonatomic, strong) NSDate    * date;

+ (MealReference *) referenceWithMealName:(NSString *)name onDate:(NSDate *)date;
+ (DiningMeal *) mealForReference:(MealReference *)reference atVenueWithShortName:(NSString *)venueShortName;

- (NSString *) cacheName;

@end
