#import <UIKit/UIKit.h>

@class MITDiningMealSummary;

@interface MITDiningScheduleCell : UITableViewCell

- (void)setMealSummary:(MITDiningMealSummary *)mealSummary;
+ (CGFloat)heightForMealSummary:(MITDiningMealSummary *)mealSummary
              tableViewWidth:(CGFloat)width;
@end
