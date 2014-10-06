#import <UIKit/UIKit.h>
#import "MITDiningRefreshDataProtocols.h"
@class MITDiningDining;

@interface MITDiningHouseVenueListViewController : UITableViewController <MITDiningRefreshableViewController>

@property (nonatomic, strong) MITDiningDining *diningData;

@property (nonatomic, weak) id<MITDiningRefreshRequestDelegate> refreshDelegate;

@end
