#import <UIKit/UIKit.h>

@class MITDiningMeal;
@class MITDiningHouseDay;

@interface MITDiningHouseMealSelectionView : UIView

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *mealTimeLabel;

@property (weak, nonatomic) IBOutlet UIButton *nextMealButton;
@property (weak, nonatomic) IBOutlet UIButton *previousMealButton;

- (void)setMeal:(MITDiningMeal *)meal forDay:(MITDiningHouseDay *)day;

@end
