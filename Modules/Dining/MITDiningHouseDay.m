#import "MITDiningHouseDay.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningMeal.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningMealSummary.h"

@implementation MITDiningHouseDay

@dynamic dateString;
@dynamic message;
@dynamic houseVenue;
@dynamic meals;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"date" : @"dateString"}];
    [mapping addAttributeMappingsFromArray:@[@"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"meals" toKeyPath:@"meals" withMapping:[MITDiningMeal objectMapping]]];

    mapping.assignsNilForMissingRelationships = YES;
    mapping.assignsDefaultValueForMissingAttributes = YES;
    
    return mapping;
}

#pragma mark - Convenience Methods

+ (NSArray *)mealNames
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
        for (MITDiningMeal *meal in self.sortedMealsArray) {
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

- (NSArray *)sortedMealsArray
{
    return [self.meals sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MITDiningMeal *meal1 = obj1;
        MITDiningMeal *meal2 = obj2;
        return [meal1.startTime compare:meal2.startTime];
    }];
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
    return [[self sortedMealsArray] firstObject];
}

- (MITDiningMeal *)lastMealInDay
{
    return [[self sortedMealsArray] lastObject];
}

- (MITDiningMealSummary *)mealSummaryForDay
{
    MITDiningMealSummary *mealSummary = [[MITDiningMealSummary alloc] init];
    mealSummary.meals = [self sortedMealsArray];
    mealSummary.startDate =
    mealSummary.endDate = self.date;
    
    return mealSummary;
}

+ (NSDateFormatter *)houseDayDateFormatter
{
    static NSDateFormatter *formatter;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
    }
    return formatter;
}

- (NSDate *)date
{
    return [[MITDiningHouseDay houseDayDateFormatter] dateFromString:self.dateString];
}

@end
