#import "MITDiningHouseMealSelectionView.h"
#import "MITDiningMeal.h"
#import "MITDiningHouseDay.h"
#import "Foundation+MITAdditions.h"

@implementation MITDiningHouseMealSelectionView

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor colorWithRed:244.0/255.0 green:245.0/255.0 blue:248.0/255.0 alpha:1.0];
}

- (void)setMeal:(MITDiningMeal *)meal
{
    _meal = meal;
    self.dateLabel.text = [self stringForMealDate:meal.houseDay.date];
    self.mealTimeLabel.text = [self.meal nameAndHoursDescription];
    
}

- (NSString *)stringForMealDate:(NSDate *)date
{
    static NSDateFormatter *dayOfWeekFormatter;
    if (!dayOfWeekFormatter) {
        dayOfWeekFormatter = [[NSDateFormatter alloc] init];
        [dayOfWeekFormatter setDateFormat:@"EEEE"];
    }
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM d"];
    }

    if ([date isToday]) {
        return [NSString stringWithFormat:@"Today, %@", [dateFormatter stringFromDate:date]];
    }
    else if ([date isTomorrow]) {
        return [NSString stringWithFormat:@"Tomorrow, %@", [dateFormatter stringFromDate:date]];
    }
    else if ([date isYesterday]) {
        return [NSString stringWithFormat:@"Yesterday, %@", [dateFormatter stringFromDate:date]];
    }
    else {
        return [NSString stringWithFormat:@"%@, %@", [dayOfWeekFormatter stringFromDate:date], [dateFormatter stringFromDate:date]];
    }
}

@end
