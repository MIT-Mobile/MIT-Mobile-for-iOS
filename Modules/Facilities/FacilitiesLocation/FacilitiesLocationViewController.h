#import <UIKit/UIKit.h>
#import "FacilitiesLocationData.h"

@class MITLoadingActivityView;


@interface FacilitiesLocationViewController : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
    MITLoadingActivityView *_loadingView;
    
    FacilitiesLocationData *_locationData;
    FacilitiesDisplayType _viewMode;
    NSArray *_cachedData;
    NSArray *_filteredData;
    NSPredicate *_filterPredicate;
    
    BOOL _isLoadingData;
}

@property (nonatomic,retain) IBOutlet UITableView* tableView;
@property (nonatomic,retain) MITLoadingActivityView* loadingView;
@property (retain) FacilitiesLocationData* locationData;
@property (nonatomic,retain) NSPredicate* filterPredicate;

@end
