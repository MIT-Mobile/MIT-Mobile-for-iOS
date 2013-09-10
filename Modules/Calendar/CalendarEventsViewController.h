#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "EventCategoriesTableView.h"
#import "OpenHouseTableView.h"
#import "EventListTableView.h"
#import "CalendarMapView.h"
#import "DatePickerViewController.h"
#import "MITSearchDisplayController.h"
#import "CalendarDataManager.h"
#import "NavScrollerView.h"

@class MITSearchDisplayController;

@class EventListTableView;
@class CalendarEventMapAnnotation;
@class MITEventList;

@interface CalendarEventsViewController : UIViewController <UIScrollViewDelegate, UISearchBarDelegate,
MITMapViewDelegate, NavScrollerDelegate,
DatePickerViewControllerDelegate, CalendarDataManagerDelegate>


@property (nonatomic, strong) EventCategory *category;
@property (nonatomic, strong) MITEventList *activeEventList;
@property (nonatomic, strong) UIViewController *childViewController;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CalendarMapView *mapView;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, copy) NSArray *events;
@property (nonatomic, copy) NSString *lastSearchTerm;

@property (nonatomic) BOOL showScroller;
@property (nonatomic) BOOL showList;


- (void)makeRequest;
- (void)makeSearchRequest:(NSString *)searchTerms;
- (void)makeCategoriesRequest;

- (void)mapButtonToggled;
- (void)listButtonToggled;

- (void)reloadView:(MITEventList *)listType;
- (void)selectScrollerButton:(NSString *)buttonTitle;


@end

