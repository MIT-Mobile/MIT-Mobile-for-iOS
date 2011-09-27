#import <UIKit/UIKit.h>
#import "MITLoadingActivityView.h"

@interface FacilitiesTypeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSDictionary *_userData;
    UITableView *_tableView;
    MITLoadingActivityView *_loadingView;
}

@property (nonatomic,copy) NSDictionary *userData;
@property (nonatomic,retain) UITableView* tableView;
@property (nonatomic, retain) MITLoadingActivityView *loadingView;
@end
