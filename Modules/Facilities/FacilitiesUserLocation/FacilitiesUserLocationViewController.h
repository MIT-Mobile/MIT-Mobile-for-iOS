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
    
    // Used in the CLLocationManager Delegate methods to keep
    // track of the most accurate location we received that is
    // greater than our desired accuracy before the location
    // timeout is reached.
    CLLocation *_currentLocation;
    NSTimer *_locationTimeout;
}

@property (nonatomic,retain) IBOutlet UITableView* tableView;
@property (nonatomic,retain) MITLoadingActivityView* loadingView;
@property (nonatomic,retain) CLLocationManager* locationManager;

@end
