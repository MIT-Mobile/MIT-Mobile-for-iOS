#import <UIKit/UIKit.h>
#import "FacilitiesLocationData.h"


@interface FacilitiesLocationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
    UIActivityIndicatorView *_activityIndicator;
    CLLocationManager *_locationManager;
    
    FacilitiesLocationData *_locationData;
    FacilitiesDisplayType _viewMode;
    NSArray *_cachedData;
    NSArray *_filteredData;
    NSPredicate *_filterPredicate;
}

@property (nonatomic,retain) IBOutlet UITableView* tableView;
@property (nonatomic,retain) IBOutlet UIActivityIndicatorView* activityIndicator;
@property (nonatomic,retain) CLLocationManager* locationManager;
@property (retain) FacilitiesLocationData* locationData;
@property (nonatomic,retain) NSPredicate* filterPredicate;

@end
