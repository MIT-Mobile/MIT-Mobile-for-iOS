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

@property (nonatomic, strong) TourSiteOrRoute *siteOrRoute;
@property (nonatomic, strong) CampusTourSideTrip *sideTrip;
@property (nonatomic, strong) TourSiteOrRoute *firstSite;
@property (nonatomic, strong) NSArray *sites;
@property (nonatomic,getter=isShowingConclusionScreen) BOOL showingConclusionScreen;

- (IBAction)previousButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)overviewButtonPressed:(id)sender;

@end
