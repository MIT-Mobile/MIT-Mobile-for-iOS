#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"
#import "ConnectionWrapper.h"

@class TourStartLocation;
@class TourOverviewViewController;

@interface StartingLocationViewController : UIViewController <UIWebViewDelegate, ConnectionWrapperDelegate> {
    NSMutableArray *_connections;
}

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSArray *startingLocations;
@property (nonatomic, assign) TourOverviewViewController *overviewController;

@end

