#import <UIKit/UIKit.h>
#import "LibrariesLocationsHours.h"

typedef enum {
    LibrariesDetailStatusLoaded,
    LibrariesDetailStatusLoading,
    LibrariesDetailStatusLoadingFailed
} LibrariesDetailStatus;

@interface LibrariesLocationsHoursDetailViewController : UITableViewController <UIWebViewDelegate> {
    
}

@property (retain, nonatomic) LibrariesLocationsHours *library;
@property (nonatomic) LibrariesDetailStatus librariesDetailStatus;
@property (nonatomic) CGFloat contentRowHeight;
@property (retain, nonatomic) UIWebView *contentWebView;

@end
