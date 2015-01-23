#import <UIKit/UIKit.h>

@class MITDiningMeal;
@class MITDiningHouseDay;

@interface MITDiningHouseMealListViewController : UIViewController

@property (nonatomic, strong) MITDiningMeal *meal;
@property (nonatomic, strong) MITDiningHouseDay *day;

- (void)applyFilters:(NSSet *)filters;

@end
