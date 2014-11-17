#import <UIKit/UIKit.h>

@class MITDiningMeal;

@interface MITDiningHouseMealListViewController : UITableViewController

@property (nonatomic, strong) MITDiningMeal *meal;

- (void)applyFilters:(NSSet *)filters;

@end
