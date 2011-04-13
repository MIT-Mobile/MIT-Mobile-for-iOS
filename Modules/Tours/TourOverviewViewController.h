#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "FlowCoverView.h"
#import "MITThumbnailView.h"
#import "ConnectionWrapper.h"
#import "ToursDataManager.h"

@class CampusTour;
@class FlowCoverView;
@class TourMapAnnotation;
@class CampusTourSideTrip;

@interface TourOverviewViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MITMapViewDelegate, FlowCoverViewDelegate, UIAlertViewDelegate, ConnectionWrapperDelegate> {
    
    UITableView *_tableView;
    MITMapView *_mapView;
    BOOL displayingMap;
    NSArray *_sites;
    FlowCoverView *coverView;
    CLLocation *_userLocation;
    BOOL _didSelectAnnotation;
    
    IBOutlet UIToolbar *toolBar;
    IBOutlet UISegmentedControl *mapListToggle;

    IBOutlet UIBarButtonItem *locateUserButton;
    IBOutlet UIBarButtonItem *leftSideFixedSpace;
    
    NSInteger selectedSiteIndex;
    TourMapAnnotation *selectedAnnotation;

    UIInterfaceOrientation currentOrientation;
    
    // currently we can be a modal view invoked from StartingLocationVC or SiteDetailVC
    UIViewController *callingViewController;
    
    // if we are invokded from a sideTrip
    // this needs to be set
    CampusTourSideTrip *sideTrip;
}

- (void)showMap:(BOOL)showMap;

- (IBAction)mapListToggled:(id)sender;
- (IBAction)locateUserPressed:(id)sender;

- (void)hideCoverView;
- (void)dismiss:(id)sender;
- (void)selectAnnotationForSite:(TourSiteOrRoute *)currentSite;

@property (nonatomic, retain) CLLocation *userLocation;
@property (nonatomic, retain) NSArray *sites;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MITMapView *mapView;
@property (nonatomic, assign) UIViewController *callingViewController;
@property (nonatomic, retain) CampusTourSideTrip *sideTrip;
@property (nonatomic, retain) TourMapAnnotation *selectedAnnotation;

@end

@class TourSiteOrRoute;

@interface TourOverviewTableViewCell : UITableViewCell <MITThumbnailDelegate>
{
    TourSiteOrRoute *_site;
    TourSiteVisitStatus visitStatus;
}

@property (nonatomic, assign) TourSiteVisitStatus visitStatus;
@property (nonatomic, retain) TourSiteOrRoute *site;

@end

