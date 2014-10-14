#import <Foundation/Foundation.h>

@class MITDiningMeal, MITDiningAggregatedMeal, MITDiningHouseVenue;

@interface MITDiningComparisonDataManager : NSObject

@property (nonatomic, strong) NSArray *houseVenues;
@property (nonatomic, readonly) NSArray *aggregatedMeals;

- (NSInteger)indexOfAggregatedMealForDate:(NSDate *)date mealName:(NSString *)mealName;
- (MITDiningMeal *)mealForAggregatedMeal:(MITDiningAggregatedMeal *)aggregatedMeal inVenue:(MITDiningHouseVenue *)venue;

@end
