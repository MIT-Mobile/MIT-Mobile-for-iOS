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
    self.dateLabel.text = [meal.houseDay.date todayTomorrowYesterdayString];
    self.mealTimeLabel.text = [self.meal nameAndHoursDescription];
}

@end
