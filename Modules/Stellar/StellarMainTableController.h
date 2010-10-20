
#import <Foundation/Foundation.h>
#import	"StellarCourseGroup.h"
#import "StellarModel.h"
#import "StellarSearch.h"
#import "MITSearchEffects.h"


@interface StellarMainTableController : UITableViewController <CoursesLoadedDelegate, ClearMyStellarDelegate> {
	NSArray *courseGroups;
	NSArray *myStellar;
	BOOL myStellarUIisUpToDate;
	StellarSearch *stellarSearch;
	UISearchDisplayController *searchController;
	MITSearchEffects *translucentOverlay;
	UIView *loadingView;
}

@property (retain) NSArray *courseGroups;
@property (retain) NSArray *myStellar;
@property (retain) UISearchDisplayController *searchController;
@property (retain) UIControl *translucentOverlay;
@property (retain) UIView *loadingView;
@property (readonly) BOOL myStellarUIisUpToDate;

- (void) reloadMyStellarData;
- (void) reloadMyStellarUI;

- (void) showSearchResultsTable;
- (void) showTranslucentOverlay;
- (void) showLoadingView;
- (void) hideSearchResultsTable;
- (void) hideTranslucentOverlay;
- (void) hideLoadingView;

@end
