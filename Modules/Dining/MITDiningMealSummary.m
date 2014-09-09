#import "MITDiningMealSummary.h"
#import "Foundation+MITAdditions.h"
#import "MITDiningMeal.h"

@implementation MITDiningMealSummary

- (BOOL)mealSummaryContainsSameMeals:(MITDiningMealSummary *)mealSummary
{
    if (self.meals.count != mealSummary.meals.count) {
        return NO;
    }
    else {
        // The meals are already in sorted order
        for (int i = 0; i < self.meals.count;  i++) {
            if (![self.meals[i] isSuperficiallyEqualToMeal:mealSummary.meals[i]]) {
                return NO;
            }
        }
        return YES;
    }
}

+ (NSDateFormatter *)mealSummaryFormatter
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EE"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return dateFormatter;
}

- (NSString *)dateRangesString
{
    NSString *startString = [[MITDiningMealSummary mealSummaryFormatter] stringFromDate:self.startDate];
    NSString *endString = [[MITDiningMealSummary mealSummaryFormatter] stringFromDate:self.endDate];
    
    if ([startString isEqualToString:endString]) {
        return startString;
    } else {
        return [[NSString stringWithFormat:@"%@ - %@", startString, endString] lowercaseString];
    }
}

- (NSString *)mealNamesStringsOnSeparateLines
{
    NSString *mealNamesString = @"";
    for (MITDiningMeal *meal in self.meals) {
        mealNamesString = [mealNamesString stringByAppendingString:[NSString stringWithFormat:@"%@\n", [meal.name capitalizedString]]];
    }
    return mealNamesString;
}

- (NSString *)mealTimesStringsOnSeparateLines
{
    NSString *mealTimesString = @"";
    for (MITDiningMeal *meal in self.meals) {
        mealTimesString =  [mealTimesString stringByAppendingString:[NSString stringWithFormat:@"%@\n", [meal mealHoursDescription]]];
    }
    return mealTimesString;
}

@end