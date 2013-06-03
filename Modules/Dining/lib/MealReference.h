
#import <Foundation/Foundation.h>
#import "DiningMeal.h"

@interface MealReference : NSObject

@property (nonatomic, strong) NSString  * name;
@property (nonatomic, strong) NSDate    * date;

+ (MealReference *) referenceWithMealName:(NSString *)name onDate:(NSDate *)date;
+ (DiningMeal *) mealForReference:(MealReference *)reference atVenueWithShortName:(NSString *)venueShortName;

@end
