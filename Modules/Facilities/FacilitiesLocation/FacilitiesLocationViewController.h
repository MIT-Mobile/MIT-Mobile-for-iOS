#import <UIKit/UIKit.h>

@class FacilitiesLocation;
@class FacilitiesCategory;
@class MITLoadingActivityView;
@class FacilitiesLocationData;
@class HighlightTableViewCell;
@class FacilitiesLocationSearch;

@interface FacilitiesLocationViewController : UIViewController 
@property (nonatomic,strong) UITableView* tableView;
@property (nonatomic,strong) FacilitiesCategory* category;

- (NSArray*)resultsForSearchString:(NSString*)searchText;
@end
