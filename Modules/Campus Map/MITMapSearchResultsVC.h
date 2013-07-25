
#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class TouchableTableView;

@interface MITMapSearchResultsVC : UIViewController <UITableViewDelegate, 
																UITableViewDataSource, 
																UISearchBarDelegate> 

@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@property BOOL isCategory;

@end
