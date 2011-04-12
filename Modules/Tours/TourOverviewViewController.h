#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "FlowCoverView.h"
#import "MITThumbnailView.h"
#import "ConnectionWrapper.h"
#import "ToursDataManager.h"
#import "TourComponent.h"

@class CampusTour;
@class FlowCoverView;
@class TourSiteMapAnnotation;

@interface TourOverviewViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MITMapViewDelegate, FlowCoverViewDelegate, UIAlertViewDelegate, ConnectionWrapperDelegate> {
    
    UITableView *_tableView;
    MITMapView *_mapView;
    BOOL displayingMap;
    NSMutableArray *_components; // Will contain TourComponent objects.
    FlowCoverView *coverView;
    CLLocation *_userLocation;
    BOOL _didSelectAnnotation;
    
    IBOutlet UIToolbar *toolBar;
    IBOutlet UISegmentedControl *mapListToggle;

    IBOutlet UIBarButtonItem *locateUserButton;
    
    NSInteger selectedSiteIndex;
    TourSiteMapAnnotation *selectedAnnotation;

    UIInterfaceOrientation currentOrientation;
    
    // currently we can be a modal view invoked from StartingLocationVC or SiteDetailVC
    UIViewController *callingViewController;
}

- (void)showMap:(BOOL)showMap;

- (IBAction)mapListToggled:(id)sender;
- (IBAction)locateUserPressed:(id)sender;
- (IBAction)toggleHideSideTrips:(id)sender;

- (void)hideCoverView;
- (void)dismiss:(id)sender;
- (void)selectAnnotationForSite:(TourSiteOrRoute *)currentSite;

@property (nonatomic, retain) CLLocation *userLocation;
@property (nonatomic, retain) NSMutableArray *components;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITMapView *mapView;
@property (nonatomic, assign) UIViewController *callingViewController;
@property (nonatomic, retain) TourSiteMapAnnotation *selectedAnnotation;
@property (nonatomic, retain) UIBarButtonItem *sideTripsItem;
@property (assign) BOOL hideSideTrips;

@end

@class TourSiteOrRoute;

@interface TourOverviewTableViewCell : UITableViewCell <MITThumbnailDelegate>
{
    TourComponent *tourComponent; // Either a TourSiteOrRoute or a CampusTourSideTrip.
    TourSiteVisitStatus visitStatus;
}

@property (nonatomic, assign) TourSiteVisitStatus visitStatus;
@property (nonatomic, retain) TourComponent *tourComponent;

@end

