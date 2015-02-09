#import "MITDiningComparisonDataManager.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningAggregatedMeal.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"

@interface MITDiningComparisonDataManager ()

@property (nonatomic, strong, readwrite) NSArray *aggregatedMeals;

@end

@implementation MITDiningComparisonDataManager

- (void)setHouseVenues:(NSArray *)houseVenues
{
    _houseVenues = houseVenues;
    [self updateAggregatedMeals];
}

- (void)updateAggregatedMeals
{
    NSDictionary *houseDaysByDate = [self houseDaysKeyedByDate];
    
    self.aggregatedMeals = [self mealsArrayForHouseDaysDateKeyedDictionary:houseDaysByDate];
}

- (NSDictionary *)houseDaysKeyedByDate
{
    NSMutableDictionary *houseDaysByDate = [[NSMutableDictionary alloc] init];
    
    for (MITDiningHouseVenue *houseVenue in self.houseVenues) {
        for (MITDiningHouseDay *houseDay in houseVenue.mealsByDay) {
            
            NSDate *keyDate = [houseDay.date startOfDay];
            
            if (!houseDaysByDate[keyDate]) {
                houseDaysByDate[keyDate] = [[NSMutableArray alloc] init];
            }
            [houseDaysByDate[keyDate] addObject:houseDay];
        }
    }
    return houseDaysByDate;
}

- (NSArray *)mealsArrayForHouseDaysDateKeyedDictionary:(NSDictionary *)houseDaysByDate
{
    NSArray *sortedDateKeys = [[houseDaysByDate allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSDate *)obj1 compare:(NSDate *)obj2];
    }];

    NSMutableArray *mealsArray = [[NSMutableArray alloc] init];
    
    // 4 Nested for loops deserve some explanation, so.... Loop through all the dates which have at least 1 house day...
    for (NSDate *dateKey in sortedDateKeys) {
        // This array has a given day for all venues, i.e. monday of all venues
        NSArray *houseDayArray = houseDaysByDate[dateKey];
        
        // Loop through all the possible meals for a day (breakfast, brunch, lunch, dinner)...
        for (NSString *mealName in [MITDiningHouseDay mealNames]) {
            
            // And loop through the days across all venues matching the date...
            for (MITDiningHouseDay *houseDay in houseDayArray) {
                MITDiningAggregatedMeal *aggregatedMeal = nil;
                
                // ...checking to see if a given meal exists for that venue on that day.
                for (MITDiningMeal *meal in houseDay.meals) {
                    
                    // If it does, then add that an aggregated meal with that name on that day to the list.
                    if ([[meal.name lowercaseString] isEqualToString:[mealName lowercaseString]]) {
                        aggregatedMeal = [[MITDiningAggregatedMeal alloc] initWithVenues:self.houseVenues date:dateKey mealName:mealName];
                        [mealsArray addObject:aggregatedMeal];
                        break;
                    }
                }
                // Stop checking other venues to see if they also have a meal with that name, it doesn't matter, we've already got an aggregated meal.
                if (aggregatedMeal) {
                    break;
                }
            }
        }
    }
    
    return mealsArray;
}

- (NSInteger)indexOfAggregatedMealForDate:(NSDate *)date mealName:(NSString *)mealName
{
    date = [date dateWithoutTime];
    NSString *lowercaseMealName = mealName.lowercaseString;
    for (MITDiningAggregatedMeal *aggregatedMeal in self.aggregatedMeals) {
        if ([aggregatedMeal.date isEqualToDateIgnoringTime:date] && (!mealName || [aggregatedMeal.mealName.lowercaseString isEqualToString:lowercaseMealName])) {
            return [self.aggregatedMeals indexOfObject:aggregatedMeal];
        }
    }
    return 0;
}

- (MITDiningMeal *)mealForAggregatedMeal:(MITDiningAggregatedMeal *)aggregatedMeal inVenue:(MITDiningHouseVenue *)venue
{
    BOOL matchedDay = NO;
    BOOL matchedMealName = NO;
    MITDiningMeal *matchedMeal = nil;
    for (MITDiningMeal *meal in [venue sortedMealsInWeek]) {
        if ([[meal.houseDay.date dateWithoutTime] compare:[aggregatedMeal.date dateWithoutTime]] == NSOrderedSame) {
            matchedMeal = meal;
            matchedDay = YES;
            if ([[meal.name lowercaseString] isEqualToString:[aggregatedMeal.mealName lowercaseString]]) {
                matchedMealName = YES;
            }
        }
        if (matchedDay && matchedMealName) {
            break;
        }
    }
    return matchedMeal;
}

@end
