#import "MITDiningMeal.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMenuItem.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningMeal

@dynamic endTimeString;
@dynamic message;
@dynamic name;
@dynamic startTimeString;
@dynamic houseDay;
@dynamic items;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"start_time" : @"startTimeString",
                                                  @"end_time" : @"endTimeString"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"items" toKeyPath:@"items" withMapping:[MITDiningMenuItem objectMapping]]];
    
    return mapping;
}

- (NSString *)mealHoursDescription
{
    NSString *description = nil;
    if (!self.startTimeString || !self.endTimeString) {
        description = self.message;
    } else {
        NSString *startString = [self.startTime MITShortTimeOfDayString];
        NSString *endString = [self.endTime MITShortTimeOfDayString];
        
        description = [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    }
    return description;
}

- (NSString *)nameAndHoursDescription
{
    return [NSString stringWithFormat:@"%@ %@", [self.name capitalizedString], [self mealHoursDescription]];
}

// This checks only if the meals are the same meal (i.e. breakfast) and at the same time of day... it doesn't check what day they're on, or if the menu items are the same.
- (BOOL)isSuperficiallyEqualToMeal:(MITDiningMeal *)meal
{
    return ([[self.name lowercaseString] isEqualToString:[meal.name lowercaseString]] && ([self.message isEqualToString:meal.message] ||
                                              ([self.startTimeString isEqualToString:meal.startTimeString] &&
                                               [self.endTimeString isEqualToString:meal.endTimeString])));
}

+ (NSDateFormatter *)mealDateFormatter
{
    static NSDateFormatter *mealFormatter;
    if (!mealFormatter) {
        mealFormatter = [[NSDateFormatter alloc] init];
        [mealFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
    }
    return mealFormatter;
}

- (NSDate *)startTime
{
    NSString *dateString = [NSString stringWithFormat:@"%@ %@", self.houseDay.dateString, self.startTimeString];
    return [[MITDiningMeal mealDateFormatter] dateFromString:dateString];
}

- (NSDate *)endTime
{
    NSString *dateString = [NSString stringWithFormat:@"%@ %@", self.houseDay.dateString, self.endTimeString];
    return [[MITDiningMeal mealDateFormatter] dateFromString:dateString];
}

@end
