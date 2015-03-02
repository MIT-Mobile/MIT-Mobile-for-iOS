#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "MITDiningLocation.h"
#import "MITDiningVenues.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningMealSummary.h"

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
    mapping.assignsNilForMissingRelationships = YES;
    
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

- (NSArray *)sortedMealsInWeek
{
    NSMutableArray *allMeals = [[NSMutableArray alloc] init];
    for (MITDiningHouseDay *houseDay in self.mealsByDay) {
        [allMeals addObjectsFromArray:[houseDay sortedMealsArray]];
    }
    return allMeals;
}

- (NSArray *)groupedMealTimeSummaries
{
    NSMutableArray *groupedMealSummaries = [[NSMutableArray alloc] init];
    
    MITDiningMealSummary *mealSummary;
    
    for (MITDiningHouseDay *houseDay in self.mealsByDay) {
        MITDiningMealSummary *mealSummaryInDay = [houseDay mealSummaryForDay];
        if (mealSummary) {
            if ([mealSummary mealSummaryContainsSameMeals:mealSummaryInDay]) {
                mealSummary.endDate = mealSummaryInDay.endDate;
            }
            else {
                [groupedMealSummaries addObject:mealSummary];
                mealSummary = mealSummaryInDay;
            }
        }
        else {
            mealSummary = mealSummaryInDay;
        }
    }
    if (mealSummary) {
        [groupedMealSummaries addObject:mealSummary];
    }
    
    return groupedMealSummaries;
}

@end
