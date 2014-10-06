#import <UIKit/UIKit.h>

@class MITDiningMeal;

@interface MITDiningHouseMealSelectionView : UIView

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *mealTimeLabel;

@property (weak, nonatomic) IBOutlet UIButton *nextMealButton;
@property (weak, nonatomic) IBOutlet UIButton *previousMealButton;

@property (nonatomic, strong) MITDiningMeal *meal;

@end
