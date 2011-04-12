#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleDataManager.h"
#import "CampusMapToolbar.h"
#import "MITMobileWebAPI.h"
#import "MITModuleURL.h"
#import "CMModule.h"



@class MITMapSearchResultsVC;
@class MapSelectionController;

@interface CampusMapViewController : UIViewController <UISearchBarDelegate, 
														MITMapViewDelegate,
														JSONLoadedDelegate,
														ShuttleDataManagerDelegate, 
														UIAlertViewDelegate>
{

	// the MIT map module in which this view controller is created. 
	CMModule* _campusMapModule;
	
	// our map view controller which renders the map display
	MITMapView* _mapView;
	
	CampusMapToolbar* _toolBar;

	UIBarButtonItem* _geoButton;
	
	UIBarButtonItem* _cancelSearchButton;
	
	UIBarButtonItem* _shuttleButton;
	
	NSArray* _searchResults;
	
	BOOL _hasSearchResults;
	
	NSArray* _filteredSearchResults;
	 
	SEL _searchFilter;
	
	NSArray* _categories;
	
	UITableView* _categoryTableView;
	 
	NSString* _lastSearchText;
	
	BOOL _displayShuttles;
	
	NSMutableArray* _shuttleAnnotations;
	
	// flag indicating whether to display a list of search results or categories. 
	BOOL _displayingList;
	
	// view controller for our search results list display
	MITMapSearchResultsVC* _searchResultsVC;
	
	// bar button to switch view types. 
	UIBarButtonItem* _viewTypeButton;
	
	IBOutlet UISearchBar* _searchBar;
	
	// a custom button since we are not using the default bookmark button
	IBOutlet UIButton* _bookmarkButton;
	
	MapSelectionController* _selectionVC;
	
	// these are used for saving state
	MITModuleURL* url;
    
    CLLocation *_userLocation;
}

@property (nonatomic, retain) UIBarButtonItem* geoButton;
@property (nonatomic, retain) NSArray* searchResults;
@property (nonatomic, assign) CMModule* campusMapModule;

@property (nonatomic, retain) CLLocation *userLocation;
@property (nonatomic, readonly) MITMapView* mapView;
@property (nonatomic, retain) NSString* lastSearchText;
@property (nonatomic, assign) BOOL hasSearchResults;
@property (nonatomic, assign) BOOL displayingList;
@property (nonatomic, readonly) UISearchBar* searchBar;
@property (nonatomic, readonly) MITModuleURL* url;

// execute a search
-(void) search:(NSString*)searchText;

// this is called in handleLocalPath: query: and also by setSearchResults:
-(void) setSearchResultsWithoutRecentering:(NSArray*)searchResults;

-(void) setSearchResults:(NSArray *)searchResults;

// set the search results with a filter. Filter will be the unique category for
// each of the search results. So if each building should be unique, filter can be bldgnum
-(void) setSearchResults:(NSArray *)searchResults withFilter:(SEL)filter;

// show the list view. If false, hides the list view so the map is displayed. 
-(void) showListView:(BOOL)showList;

// a convenience method for adding or removing "userLoc" from the url's path (for saving state)
-(void) setURLPathUserLocation;

// push an annotations detail page onto the stack
-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

@end
