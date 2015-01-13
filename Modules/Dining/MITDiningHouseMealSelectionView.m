#import "MITDiningHouseMealSelectionView.h"
#import "MITDiningMeal.h"
#import "MITDiningHouseDay.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"

@interface MITDiningHouseMealSelectionView ()
@property (nonatomic, strong) MITDiningMeal *meal;
@end

@implementation MITDiningHouseMealSelectionView

- (void)awakeFromNib
{
    self.backgroundColor = [UIColor colorWithRed:244.0/255.0 green:245.0/255.0 blue:248.0/255.0 alpha:1.0];
    self.mealTimeLabel.textColor = [UIColor mit_greyTextColor];
    [self.previousMealButton setImage:[UIImage imageNamed:@"global/action-arrow-left.png"] forState:UIControlStateNormal];
    [self.nextMealButton setImage:[UIImage imageNamed:@"global/action-arrow-right.png"] forState:UIControlStateNormal];
}

- (void)setMeal:(MITDiningMeal *)meal forDay:(MITDiningHouseDay *)day
{
    if (meal) {
        self.meal = meal;
        self.dateLabel.text = [meal.houseDay.date todayTomorrowYesterdayString];
        self.mealTimeLabel.text = [self.meal nameAndHoursDescription];
    } else {
        self.dateLabel.text = [day.date todayTomorrowYesterdayString];
        self.mealTimeLabel.text = day.message;
    }
}

@end
