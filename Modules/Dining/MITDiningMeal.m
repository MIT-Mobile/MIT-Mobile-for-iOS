#import "MITDiningMeal.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMenuItem.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningMeal

@dynamic endTime;
@dynamic message;
@dynamic name;
@dynamic startTime;
@dynamic houseDay;
@dynamic items;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"start_time" : @"startTime",
                                                  @"end_time" : @"endTime"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"message"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"items" toKeyPath:@"items" withMapping:[MITDiningMenuItem objectMapping]]];
    
    return mapping;
}

- (NSString *)mealHoursDescription
{
    NSString *description = nil;
    if (!self.startTime || !self.endTime) {
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
    return ([self.name isEqualToString:meal.name] && ([self.message isEqualToString:meal.message] ||
                                              ([self.startTime isEqualToTimeIgnoringDay:meal.startTime] &&
                                               [self.endTime isEqualToTimeIgnoringDay:meal.endTime])));
}

@end
