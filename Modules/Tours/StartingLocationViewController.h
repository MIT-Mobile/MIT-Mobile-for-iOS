#import <UIKit/UIKit.h>
#import "MITThumbnailView.h"

@class TourStartLocation;
@class TourOverviewViewController;

@interface StartingLocationViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSArray *startingLocations;
@property (nonatomic, assign) TourOverviewViewController *overviewController;

@end

