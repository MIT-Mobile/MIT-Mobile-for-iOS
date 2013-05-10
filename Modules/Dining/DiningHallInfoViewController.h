
#import <UIKit/UIKit.h>
#import "HouseVenue.h"

@interface DiningHallInfoViewController : UITableViewController

@property (nonatomic, strong) HouseVenue * venue;
@property (nonatomic, strong) NSDictionary * hallStatus;

@end
