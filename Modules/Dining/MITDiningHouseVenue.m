#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "MITDiningLocation.h"
#import "MITDiningVenues.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningHouseVenue

@dynamic iconURL;
@dynamic identifier;
@dynamic name;
@dynamic payment;
@dynamic shortName;
@dynamic location;
@dynamic mealsByDay;
@dynamic venues;


+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_name" : @"shortName",
                                                  @"icon_url" : @"iconURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"payment"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:[MITDiningLocation objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"meals_by_day" toKeyPath:@"mealsByDay" withMapping:[MITDiningHouseDay objectMapping]]];
    
    [mapping setIdentificationAttributes:@[@"identifier"]];
    
    return mapping;
}

#pragma mark - Convenience Methods

- (BOOL)isOpenNow
{
    NSDate *date = [NSDate date];
    MITDiningHouseDay *day = [self houseDayForDate:date];
    MITDiningMeal *meal = [day mealForDate:date];
    return (meal != nil);
}

- (MITDiningHouseDay *)houseDayForDate:(NSDate *)date
{
    MITDiningHouseDay *returnDay = nil;
    if (date) {
        NSDate *startOfDate = [date startOfDay];
        for (MITDiningHouseDay *day in self.mealsByDay) {
            if ([day.date isEqualToDateIgnoringTime:startOfDate]) {
                returnDay = day;
                break;
            }
        }
    }
    return returnDay;
}

- (NSString *)hoursToday
{
    MITDiningHouseDay *today = [self houseDayForDate:[NSDate date]];
    return [today dayHoursDescription];
}

// These functions are designed to return correct values regardless of the ordering of the meals coming down from the webservice, which is why they're slightly more complicated.
- (MITDiningMeal *)mealAfterMeal:(MITDiningMeal *)meal
{
    MITDiningMeal *nextMeal = [self mealWithinDayAfterMeal:meal];
    if (!nextMeal) {
        NSDate *nextDayDate = [meal.houseDay.date dateByAddingDay];
        MITDiningHouseDay *nextDay = [self houseDayForDate:nextDayDate];
        if (nextDay) {
            nextMeal = [nextDay firstMealInDay];
        }
    }
    return nextMeal;
}

- (MITDiningMeal *)mealWithinDayAfterMeal:(MITDiningMeal *)meal
{
    MITDiningHouseDay *houseDay = meal.houseDay;
    NSArray *mealNames = houseDay.mealNames;
    NSString *mealName = [meal.name lowercaseString];
    NSInteger mealIndex = [mealNames indexOfObject:mealName] + 1;
    for (int i = mealIndex; i < mealNames.count; i++) {
        MITDiningMeal *meal = [houseDay mealWithName:mealNames[i]];
        if (meal) {
            return meal;
        }
    }
    return nil;
}

- (MITDiningMeal *)mealBeforeMeal:(MITDiningMeal *)meal
{
    MITDiningMeal *previousMeal = [self mealWithinDayBeforeMeal:meal];
    if (!previousMeal) {
        NSDate *previousDayDate = [meal.houseDay.date dateBySubtractingDay];
        MITDiningHouseDay *previousDay = [self houseDayForDate:previousDayDate];
        if (previousDay) {
            previousMeal = [previousDay lastMealInDay];
        }
    }
    return previousMeal;
}

- (MITDiningMeal *)mealWithinDayBeforeMeal:(MITDiningMeal *)meal
{
    MITDiningHouseDay *houseDay = meal.houseDay;
    NSArray *mealNames = houseDay.mealNames;
    NSString *mealName = [meal.name lowercaseString];
    NSInteger mealIndex = [mealNames indexOfObject:mealName] - 1;
    for (int i = mealIndex; i > 0; i--) {
        MITDiningMeal *meal = [houseDay mealWithName:mealNames[i]];
        if (meal) {
            return meal;
        }
    }
    return nil;
}

@end
