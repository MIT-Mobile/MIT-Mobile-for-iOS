#import <UIKit/UIKit.h>
#import "MealReference.h"

@protocol MealReferenceDelegate <NSObject>

-(void) mealController:(UIViewController *) controller didUpdateMealReference:(MealReference *)updatedMealRef;

@end


@interface DiningMenuCompareViewController : UIViewController

@property (nonatomic, strong) NSSet * filtersApplied;
@property (nonatomic, strong) MealReference * mealRef;
@property (nonatomic) id<MealReferenceDelegate> delegate;

@end
