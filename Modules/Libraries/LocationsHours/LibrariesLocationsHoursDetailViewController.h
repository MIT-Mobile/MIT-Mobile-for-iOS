#import <UIKit/UIKit.h>
#import "LibrariesLocationsHours.h"
#import "MITMobileWebAPI.h"

typedef enum {
    LibrariesDetailStatusLoaded,
    LibrariesDetailStatusLoading,
    LibrariesDetailStatusLoadingFailed
} LibrariesDetailStatus;

@interface LibrariesLocationsHoursDetailViewController : UITableViewController <JSONLoadedDelegate, UIWebViewDelegate> {
    
}

@property (retain, nonatomic) LibrariesLocationsHours *library;
@property (retain, nonatomic) MITMobileWebAPI *request;
@property (nonatomic) LibrariesDetailStatus librariesDetailStatus;
@property (nonatomic) CGFloat contentRowHeight;
@property (retain, nonatomic) UIWebView *contentWebView;

@end
