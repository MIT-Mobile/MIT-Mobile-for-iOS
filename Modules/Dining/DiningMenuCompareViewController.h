#import <UIKit/UIKit.h>
#import "MealReference.h"


@interface DiningMenuCompareViewController : UIViewController
@property (nonatomic, strong) NSSet * filtersApplied;
@property (nonatomic, strong) MealReference * mealRef;
@property (nonatomic, readonly, strong) MealReference *visibleMealReference;


@end
