#import "MITDiningAggregatedMeal.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningAggregatedMeal

- (instancetype)initWithVenues:(NSArray *)venues date:(NSDate *)date mealName:(NSString *)mealName
{
    self = [super init];
    if (self) {
        self.venues = venues;
        self.date = date;
        self.mealName = mealName;
    }
    return self;
}

- (MITDiningMeal *)mealForHouseVenue:(MITDiningHouseVenue *)houseVenue
{
    MITDiningMeal *mealToReturn = nil;
    if (self.date && self.mealName) {
        MITDiningHouseDay *houseDay = [houseVenue houseDayForDate:self.date];
        
        for (MITDiningMeal *meal in houseDay.meals) {
            if ([[meal.name lowercaseString] isEqualToString:[self.mealName lowercaseString]]) {
                mealToReturn = meal;
                break;
            }
        }
    }
    return mealToReturn;
}

- (NSString *)mealDisplayTitle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    NSString *dayString;
    if ([self.date isToday]) {
        dayString = @"Today";
    } else if ([self.date isTomorrow]) {
        dayString = @"Tomorrow";
    } else if ([self.date isYesterday]) {
        dayString = @"Yesterday";
    } else {
        [dateFormatter setDateFormat:@"EEEE"];
        dayString = [dateFormatter stringFromDate:self.date];
    }
    
    [dateFormatter setDateFormat:@"MMM d"];
    NSString *fullDate = [dateFormatter stringFromDate:self.date];
    
    
    NSString * mealString = [self.mealName capitalizedString];
    return [NSString stringWithFormat:@"%@'s %@, %@", dayString, mealString, fullDate];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Meal Name: %@ Date: %@", self.mealName, self.date];
}

@end
