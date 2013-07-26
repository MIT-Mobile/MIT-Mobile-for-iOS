#import <UIKit/UIKit.h>

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;

@interface FacilitiesRoomViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) FacilitiesLocation* location;

- (NSArray*)resultsForSearchString:(NSString*)searchText;
@end
