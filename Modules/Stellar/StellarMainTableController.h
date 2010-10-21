#import <Foundation/Foundation.h>
#import	"StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "MITSearchEffects.h"
#import "MITModuleURL.h"
#import "MITSearchDisplayController.h"


@interface StellarMainTableController : UIViewController <CoursesLoadedDelegate, ClearMyStellarDelegate, UITableViewDelegate, UITableViewDataSource> {
	NSArray *courseGroups;
	NSArray *myStellar;
	BOOL myStellarUIisUpToDate;
	StellarSearch *stellarSearch;
	UISearchBar *searchBar;
	UITableView *mainTableView;
	UITableView *searchResultsTableView;
	UIView *loadingView;
	MITModuleURL *url;
	BOOL isViewAppeared;
	NSString *doSearchTerms;
	BOOL doSearchExecute;
    MITSearchDisplayController *searchController;
}

@property (retain) NSArray *courseGroups;
@property (retain) NSArray *myStellar;
@property (readonly) UITableView *searchResultsTableView;
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
