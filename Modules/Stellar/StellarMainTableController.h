#import <Foundation/Foundation.h>
#import	"StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "MITModuleURL.h"

@class MITSearchDisplayController;

@interface StellarMainTableController : UIViewController <CoursesLoadedDelegate, ClearMyStellarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (retain) NSArray *courseGroups;
@property (retain) NSArray *myStellar;
@property (readonly,strong) UITableView *searchResultsTableView;
@property (retain) UITableView *mainTableView;
@property (retain) UISearchBar *searchBar;
@property (retain) UIView *loadingView;
@property (readonly) BOOL myStellarUIisUpToDate;
@property (readonly) MITModuleURL *url;

- (void) reloadMyStellarData;
- (void) reloadMyStellarUI;
- (void) reloadMyStellarNotifications;

- (void) doSearch:(NSString *)searchTerms execute:(BOOL)execute;
- (void) showSearchResultsTable;
- (void) showLoadingView;
- (void) hideSearchResultsTable;
- (void) hideLoadingView;

@end
