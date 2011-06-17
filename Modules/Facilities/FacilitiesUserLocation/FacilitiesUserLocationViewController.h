#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class MITLoadingActivityView;

@interface FacilitiesUserLocationViewController : UIViewController <CLLocationManagerDelegate,
                                                                    UIAlertViewDelegate,
                                                                    UITableViewDataSource,
                                                                    UITableViewDelegate>
{
    UITableView *_tableView;
    MITLoadingActivityView *_loadingView;
    
    CLLocationManager *_locationManager;
    BOOL _isLocationUpdating;
    NSArray *_filteredData;
}

@property (nonatomic,retain) IBOutlet UITableView* tableView;
@property (nonatomic,retain) MITLoadingActivityView* loadingView;
@property (nonatomic,retain) CLLocationManager* locationManager;

@end
