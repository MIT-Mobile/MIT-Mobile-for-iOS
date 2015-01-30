#import <UIKit/UIKit.h>

@class MITDiningMeal, MITDiningAggregatedMeal, MITDiningComparisonDataManager, MITDiningHouseDay;

@interface MITDiningMenuComparisonViewController : UIViewController

@property (nonatomic, strong) NSSet * filtersApplied;

@property (nonatomic, strong) MITDiningMeal *visibleMeal;
@property (nonatomic, strong) MITDiningAggregatedMeal *visibleAggregatedMeal;
@property (nonatomic, strong) MITDiningHouseDay *visibleDay;

@property (nonatomic, strong) NSArray *houseVenues;

@property (nonatomic, strong) MITDiningComparisonDataManager *dataManager;

@end
