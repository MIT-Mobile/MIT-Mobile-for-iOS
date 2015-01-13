#import <UIKit/UIKit.h>

@interface MITDiningHouseHomeViewControllerPad : UIViewController

@property (nonatomic, strong) NSArray *diningHouses;
@property (nonatomic, strong) NSArray *dietaryFlagFilters;

- (void)setDietaryFlagFilters:(NSArray *)filters;
- (void)refreshForNewData;

@end
