#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"
#import "ConnectionWrapper.h"

@class TourStartLocation;
@class TourOverviewViewController;

@interface StartingLocationViewController : UIViewController <UIWebViewDelegate, ConnectionWrapperDelegate> {

    NSArray *startingLocations;
    TourOverviewViewController *overviewController;
    UIWebView *_webView;
    NSMutableArray *connections;
}

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSArray *startingLocations;
@property (nonatomic, assign) TourOverviewViewController *overviewController;

@end

