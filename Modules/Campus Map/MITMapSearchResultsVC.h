
#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class TouchableTableView;

@interface MITMapSearchResultsVC : UIViewController <UITableViewDelegate, 
																UITableViewDataSource, 
																UISearchBarDelegate> 

@property (nonatomic, copy) NSArray* searchResults;
@property (nonatomic, weak) CampusMapViewController* campusMapVC;

@property BOOL isCategory;

@end
