#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface FacilitiesUserLocation : UIViewController <CLLocationManagerDelegate,UIAlertViewDelegate> {
    UITableView *_tableView;
    UIActivityIndicatorView *_activityIndicator;
    
    CLLocationManager *_locationManager;
    NSArray *_filteredData;
}
@property (nonatomic,retain) IBOutlet UITableView* tableView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView* activityIndicator;

@property (nonatomic,retain) CLLocationManager* locationManager;

@end
