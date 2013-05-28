#import <UIKit/UIKit.h>
#import "MITMapView.h"
#import "MITThumbnailView.h"
#import "ToursDataManager.h"
#import "TourComponent.h"
#import "TourGeoLocation.h"

@class CampusTour;
@class TourMapAnnotation;
@class CampusTourSideTrip;


@interface TourOverviewViewController : UIViewController <UITableViewDataSource, 
UITableViewDelegate, MITMapViewDelegate, UIAlertViewDelegate>

- (void)showMap:(BOOL)showMap;

- (IBAction)mapListToggled:(id)sender;
- (IBAction)locateUserPressed:(id)sender;
- (IBAction)toggleHideSideTrips:(id)sender;

- (void)dismiss:(id)sender;
- (void)selectAnnotationForSite:(TourSiteOrRoute *)currentSite;

@property (nonatomic, strong) CLLocation *userLocation;
@property (nonatomic, strong) NSMutableArray *components;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MITMapView *mapView;
@property (nonatomic, assign) UIViewController *callingViewController;
@property (nonatomic, strong) CampusTourSideTrip *sideTrip;
@property (nonatomic, strong) TourMapAnnotation *selectedAnnotation;
@property (nonatomic, strong) UIBarButtonItem *sideTripsItem;
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

