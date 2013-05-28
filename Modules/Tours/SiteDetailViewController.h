#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"
#import "MITMapView.h"
#import <AVFoundation/AVFoundation.h>
@class TourSiteOrRoute;
@class CampusTourSideTrip;
@class TourComponent;
@class SuperThinProgressBar;
@class CampusTour;
@class MITMapRoute;

@interface SiteDetailViewController : UIViewController
<MITThumbnailDelegate, UIAlertViewDelegate,
UIWebViewDelegate, MITMapViewDelegate,
UITableViewDelegate, UITableViewDataSource>

- (void)jumpToSite:(NSInteger)siteIndex;

@property (nonatomic, retain) TourSiteOrRoute *siteOrRoute;
@property (nonatomic, retain) CampusTourSideTrip *sideTrip;
@property (nonatomic, retain) TourSiteOrRoute *firstSite;
@property (nonatomic, retain) NSArray *sites;
@property (nonatomic) BOOL showingConclusionScreen;

- (IBAction)previousButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)overviewButtonPressed:(id)sender;

@end
