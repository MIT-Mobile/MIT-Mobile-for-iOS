
#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class TouchableTableView;

@interface MITMapSearchResultsVC : UIViewController <UITableViewDelegate, 
																UITableViewDataSource, 
																UISearchBarDelegate> 
{

	NSArray* _searchResults;
	
	CampusMapViewController* _campusMapVC;
	
	BOOL _isCategory;
	
	IBOutlet UITableView* _tableView;

}

@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) CampusMapViewController* campusMapVC;

@property BOOL isCategory;

@end
