#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "ShuttleDataManager.h"
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

@property (nonatomic, strong) UIBarButtonItem* geoButton;
@property (nonatomic, strong) NSArray* searchResults;
@property (nonatomic, assign) CMModule* campusMapModule;

@property (nonatomic, strong) CLLocation *userLocation;
@property (nonatomic, readonly, strong) MITMapView* mapView;
@property (nonatomic, copy) NSString* lastSearchText;
@property (nonatomic) BOOL hasSearchResults;
@property (nonatomic) BOOL displayingList;
@property (nonatomic,getter = isTrackingUserLocation) BOOL trackingUserLocation;

@property (nonatomic, readonly, strong) MITModuleURL* url;

@property (nonatomic, strong) IBOutlet UISearchBar* searchBar;
@property (nonatomic, strong) IBOutlet UIButton* bookmarkButton;

// execute a search
-(void) search:(NSString*)searchText;

// this is called in handleLocalPath: query: and also by setSearchResults:
-(void) setSearchResultsWithoutRecentering:(NSArray*)searchResults;

-(void) setSearchResults:(NSArray *)searchResults;

// show the list view. If false, hides the list view so the map is displayed. 
-(void) showListView:(BOOL)showList;

// a convenience method for adding or removing "userLoc" from the url's path (for saving state)
-(void) setURLPathUserLocation;

// push an annotations detail page onto the stack
-(void) pushAnnotationDetails:(id <MKAnnotation>) annotation animated:(BOOL)animated;

@end
