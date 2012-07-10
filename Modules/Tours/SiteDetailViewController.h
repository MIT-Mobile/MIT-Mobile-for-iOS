#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"
#import "MITMapView.h"
#import "ConnectionWrapper.h"
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
ConnectionWrapperDelegate, UITableViewDelegate, UITableViewDataSource> {

    TourSiteOrRoute *_siteOrRoute;
    CampusTourSideTrip *_sideTrip;
    NSArray *_sites;
    
    MITMapView *_routeMapView;
    UIImageView *_siteImageView;
    NSString *siteTemplate;
    MITGenericMapRoute *directionsRoute;
    
    IBOutlet UIButton *backArrow;
    IBOutlet UIButton *nextArrow;
    IBOutlet UIButton *overviewButton;
    //IBOutlet UIButton *qrButton;   
    
    //BOOL showingIntroScreen;
    BOOL showingConclusionScreen;
    
    UIScrollView *oldSlidingView;
    UIScrollView *newSlidingView;
    
    TourSiteOrRoute *firstSite;
    TourSiteOrRoute *lastSite;
    
    IBOutlet SuperThinProgressBar *progressbar;
    IBOutlet UIView *fakeToolbar;
    CGFloat fakeToolbarHeightFromNIB; 
    
    AVAudioPlayer *audioPlayer;
    
    ConnectionWrapper *connection;
    UIProgressView *progressView;
}

- (void)jumpToSite:(NSInteger)siteIndex;

@property (nonatomic, retain) TourSiteOrRoute *siteOrRoute;
@property (nonatomic, retain) CampusTourSideTrip *sideTrip;
@property (nonatomic, retain) TourSiteOrRoute *firstSite;
@property (nonatomic, retain) NSArray *sites;
@property (nonatomic, retain) ConnectionWrapper *connection;
@property (nonatomic) BOOL showingConclusionScreen;

- (IBAction)previousButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)overviewButtonPressed:(id)sender;

@end
