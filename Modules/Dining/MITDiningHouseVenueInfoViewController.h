#import <UIKit/UIKit.h>

@class MITDiningHouseVenue;

@interface MITDiningHouseVenueInfoViewController : UITableViewController

@property (nonatomic, strong) MITDiningHouseVenue *houseVenue;

- (void)dismiss;

@end
