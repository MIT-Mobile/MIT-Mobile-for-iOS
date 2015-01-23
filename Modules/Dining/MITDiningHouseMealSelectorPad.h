#import <UIKit/UIKit.h>
#import "MITExtendedNavBarView.h"

@protocol MITDiningHouseMealSelectorPadDelegate;

@interface MITDiningHouseMealSelectorPad : MITExtendedNavBarView

@property (nonatomic, weak) id<MITDiningHouseMealSelectorPadDelegate>delegate;
@property (nonatomic) CGFloat horizontalInset; // Inset for left and right side of the view

- (void)setVenues:(NSArray *)venues;
- (void)selectMeal:(NSString *)meal onDate:(NSDate *)date;
- (void)refreshViews;

@end

@protocol MITDiningHouseMealSelectorPadDelegate <NSObject>

- (void)diningHouseMealSelector:(MITDiningHouseMealSelectorPad *)mealSelector didSelectMeal:(NSString *)meal onDate:(NSDate *)date;

@end