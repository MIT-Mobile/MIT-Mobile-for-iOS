#import <UIKit/UIKit.h>
#import "MITMapView.h"
//#import "ConnectionWrapper.h"
#import "PostData.h"
#import "ShuttleDataManager.h"
#import "CampusMapToolbar.h"

//@class MITMapSearchResultsTable;
@class MITMapSearchResultsVC;
@class MITMapCategory;

@interface CampusMapViewController : UIViewController <UISearchBarDelegate, 
														MITMapViewDelegate,
														PostDataDelegate,
														ShuttleDataManagerDelegate, 
														UIAlertViewDelegate>
{

	// our map view controller which renders the map display
	MITMapView* _mapView;
	
	CampusMapToolbar* _toolBar;

	UIBarButtonItem* _geoButton;
	
	UIBarButtonItem* _shuttleButton;
	
	NSArray* _searchResults;
	
	NSArray* _filteredSearchResults;
	 
	SEL _searchFilter;
	
	NSArray* _categories;
	
	MITMapCategory* _selectedCategory;
	
	UITableView* _categoryTableView;
	 
	NSString* _lastSearchText;
	
	BOOL _displayShuttles;
	
	NSMutableArray* _shuttleAnnotations;
	
	// flag indicating whether to display a list of search results or categories. 
	BOOL _displayList;
	
	// view controller for our search results list display
	MITMapSearchResultsVC* _searchResultsVC;
	
	// bar button to switch view types. 
	UIBarButtonItem* _viewTypeButton;
	
	IBOutlet UISearchBar* _searchBar;
	
}

@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) MITMapCategory* selectedCategory;

@property (readonly) MITMapView* mapView;
@property (readonly) NSString* lastSearchText;
@property (readonly) UISearchBar* searchBar;

-(void) search:(NSString*)searchText;

// set the search results with a filter. Filter will be the unique category for
// each of the search results. So if each building should be unique, filter can be bldgnum
-(void) setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter;

// show the list view. If false, hides the list view so the map is displayed. 
-(void) showListView:(BOOL)showList;

@end
