#import <UIKit/UIKit.h>
//#import "MITDiningMenuComparisonViewController.h"
#import "DiningMenuFilterViewController.h"
#import "CoreDataManager.h"
#import "MealReference.h"

@class HouseVenue;

@interface DiningHallMenuViewController : UIViewController


@property (nonatomic, strong) HouseVenue * venue;
@property (nonatomic, strong) MealReference * mealRef;

@end
