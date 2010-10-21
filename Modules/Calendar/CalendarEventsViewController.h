#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITMapView.h"
#import "CalendarConstants.h"
#import "EventCategoriesTableView.h"
#import "EventListTableView.h"
#import "CalendarMapView.h"
#import "DatePickerViewController.h"

@class MITSearchDisplayController;

@class EventListTableView;
@class CalendarEventMapAnnotation;

@interface CalendarEventsViewController : UIViewController <UIScrollViewDelegate, UISearchBarDelegate, MITMapViewDelegate, JSONLoadedDelegate, DatePickerViewControllerDelegate> {

	CalendarEventListType activeEventList; // today, browse, acad, holidays...
	NSDate *startDate;
	NSDate *endDate;
	NSArray *events;
	
	// views in the body
	UITableView *theTableView;
	CalendarMapView *theMapView;
	
	// views in the header
	UIScrollView *navScrollView;
	UISearchBar *theSearchBar;
	NSMutableArray *navButtons;
	UIButton *leftScrollButton;
	UIButton *rightScrollButton;
	
	UIView *datePicker;
	
	// search
	MITSearchDisplayController *searchController;
	UIView *loadingIndicator;
	EventListTableView *searchResultsTableView;
	CalendarMapView *searchResultsMapView;
	
	// category parameter for list of events in a category
	NSInteger theCatID;
	
	BOOL showList;
	BOOL showScroller;
	BOOL dateRangeDidChange;
	
	MITMobileWebAPI *apiRequest;
	BOOL requestDispatched;

    MITMobileWebAPI *categoriesRequest;
	BOOL categoriesRequestDispatched;
}

@property (nonatomic, assign) BOOL showScroller;
@property (nonatomic, assign) BOOL showList;
@property (nonatomic, assign) NSInteger catID;
@property (nonatomic, assign) CalendarEventListType activeEventList;

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) CalendarMapView *mapView;

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSArray *events;


- (void)abortEventListRequest;
- (void)makeRequest;
- (void)makeSearchRequest:(NSString *)searchTerms;
- (void)makeCategoriesRequest;

- (void)mapButtonToggled;
- (void)listButtonToggled;
- (void)sideButtonPressed:(id)sender;
- (void)buttonPressed:(id)sender;

- (void)reloadView:(CalendarEventListType)listType;
- (void)selectScrollerButton:(NSString *)buttonTitle;


@end

