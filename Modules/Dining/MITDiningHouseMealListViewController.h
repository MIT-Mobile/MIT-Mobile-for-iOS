#import <UIKit/UIKit.h>

@class MITDiningMeal;

@interface MITDiningHouseMealListViewController : UIViewController

@property (nonatomic, strong) MITDiningMeal *meal;

- (void)applyFilters:(NSSet *)filters;

@end
