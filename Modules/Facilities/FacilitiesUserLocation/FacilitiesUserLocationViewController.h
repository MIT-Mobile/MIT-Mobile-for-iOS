#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MITLoadingActivityView;

@interface FacilitiesUserLocationViewController : UIViewController <CLLocationManagerDelegate,
                                                                    UIAlertViewDelegate,
                                                                    UITableViewDataSource,
                                                                    UITableViewDelegate>
@property (nonatomic,strong) IBOutlet UITableView* tableView;
@end
