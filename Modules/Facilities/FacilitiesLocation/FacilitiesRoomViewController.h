#import <UIKit/UIKit.h>

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;

@interface FacilitiesRoomViewController : UIViewController
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) FacilitiesLocation* location;

- (NSArray*)resultsForSearchString:(NSString*)searchText;
@end
