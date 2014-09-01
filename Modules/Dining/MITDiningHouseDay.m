#import "MITDiningHouseDay.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningMeal.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningHouseDay

@dynamic date;
@dynamic message;
@dynamic houseVenue;
@dynamic meals;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"date", @"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"meals" toKeyPath:@"meals" withMapping:[MITDiningMeal objectMapping]]];
    
    return mapping;
}

#pragma mark - Convenience Methods

- (NSArray *)mealNames
{
    return @[@"breakfast", @"brunch", @"lunch", @"dinner"];
}

- (NSString *)dayHoursDescription
{
    NSString *dayHoursDescription = nil;
    if (self.message) {
        dayHoursDescription = self.message;
    }
    else {
        NSMutableArray *hoursStrings = [NSMutableArray array];
        for (MITDiningMeal *meal in self.meals) {
            NSString *hours = [meal mealHoursDescription];
            if (hours) {
                [hoursStrings addObject:hours];
            }
        }
        
        if ([hoursStrings count] > 0) {
            dayHoursDescription = [hoursStrings componentsJoinedByString:@", "];
        }
        else {
            dayHoursDescription = @"Closed for the day";
        }
        
    }
    return dayHoursDescription;
}

#pragma mark - Meal Helpers

- (MITDiningMeal *)mealWithName:(NSString *)name
{
    MITDiningMeal *returnMeal = nil;
    for (MITDiningMeal *meal in self.meals) {
        if ([meal.name.lowercaseString isEqualToString:name.lowercaseString]) {
            returnMeal = meal;
            break;
        }
    }
    return returnMeal;
}

- (MITDiningMeal *)mealForDate:(NSDate *)date
{
    MITDiningMeal *returnMeal = nil;
    NSTimeInterval dateInterval = [date timeIntervalSince1970];
    for (MITDiningMeal *meal in self.meals) {
        NSTimeInterval startTime = [meal.startTime timeIntervalSince1970];
        NSTimeInterval endTime = [meal.endTime timeIntervalSince1970];
        if (startTime <= dateInterval && dateInterval < endTime) {
            returnMeal = meal;
            break;
        }
    }
    return returnMeal;
}

- (MITDiningMeal *)bestMealForDate:(NSDate *)date
{
    MITDiningMeal *returnMeal = [self mealForDate:date];
    if (!returnMeal) {
        NSTimeInterval dateInterval = [date timeIntervalSince1970];
        for (MITDiningMeal *meal in self.meals) {
            NSTimeInterval startTime = [meal.startTime timeIntervalSince1970];
            if (startTime >= dateInterval) {
                returnMeal = meal;
                break;
            }
        }
    }
    if (!returnMeal) {
        returnMeal = [self.meals lastObject];
    }
    return returnMeal;
}

#pragma mark - Open/Closed Status

- (NSString *)statusStringForDate:(NSDate *)date
{
    NSString *openClosedStatus = @"Closed for the day";
    if (self.message) {
        openClosedStatus = self.message;
    } else {
        MITDiningMeal *bestMeal = [self bestMealForDate:date];
        if (bestMeal.startTime && bestMeal.endTime) {
            NSTimeInterval dateInterval = [date timeIntervalSince1970];
            NSTimeInterval bestMealStart = [bestMeal.startTime timeIntervalSince1970];
            NSTimeInterval bestMealEnd = [bestMeal.endTime timeIntervalSince1970];
            
            if (dateInterval < bestMealStart) {
                openClosedStatus = [NSString stringWithFormat:@"Opens at %@", [bestMeal.startTime MITShortTimeOfDayString]];
            } else if (dateInterval < bestMealEnd) {
                openClosedStatus = [NSString stringWithFormat:@"Open until %@", [bestMeal.endTime MITShortTimeOfDayString]];
            }
        }
    }
    
    return openClosedStatus;
}
- (NSString *)houseHoursDescription
{
    if (self.message) {
        return self.message;
    }
    
    NSMutableArray *hoursStrings = [NSMutableArray array];
    for (MITDiningMeal *meal in self.meals) {
        NSString *hours = [meal mealHoursDescription];
        if (hours) {
            [hoursStrings addObject:hours];
        }
    }
    
    if ([hoursStrings count] > 0) {
        return [hoursStrings componentsJoinedByString:@", "];
    }
    else {
        return @"Closed for the day";
    }
}

- (MITDiningMeal *)firstMealInDay
{
    for (int i = 0; i < self.mealNames.count; i++) {
        MITDiningMeal *meal = [self mealWithName:self.mealNames[i]];
        if (meal) {
            return meal;
        }
    }
    // Presuming the webservice isn't perfectly ordered, we'll default to this instead of nil
    return self.meals[0];
}

- (MITDiningMeal *)lastMealInDay
{
    for (int i = self.mealNames.count - 1; i > 0; i--) {
        MITDiningMeal *meal = [self mealWithName:self.mealNames[i]];
        if (meal) {
            return meal;
        }
    }
    return self.meals[self.meals.count - 1];
}

@end
