#import <UIKit/UIKit.h>
#import "MITDiningRefreshDataProtocols.h"

@interface MITDiningHouseHomeViewControllerPad : UIViewController <MITDiningRefreshableViewController>

@property (nonatomic, strong) NSArray *diningHouses;
@property (nonatomic, strong) NSArray *dietaryFlagFilters;

- (void)setDietaryFlagFilters:(NSArray *)filters;
- (void)refreshForNewData;

@property (nonatomic, weak) id<MITDiningRefreshRequestDelegate> refreshDelegate;

@end
