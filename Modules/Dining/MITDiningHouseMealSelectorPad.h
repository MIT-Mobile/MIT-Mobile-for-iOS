#import <UIKit/UIKit.h>

@protocol MITDiningHouseMealSelectorPadDelegate;

@interface MITDiningHouseMealSelectorPad : UIView

@property (nonatomic, weak) id<MITDiningHouseMealSelectorPadDelegate>delegate;
@property (nonatomic) CGFloat horizontalInset; // Inset for left and right side of the view

- (void)setVenues:(NSArray *)venues;
- (void)selectMeal:(NSString *)meal onDate:(NSDate *)date;
- (void)refreshViews;

@end

@protocol MITDiningHouseMealSelectorPadDelegate <NSObject>

- (void)diningHouseMealSelector:(MITDiningHouseMealSelectorPad *)mealSelector didSelectMeal:(NSString *)meal onDate:(NSDate *)date;

@end