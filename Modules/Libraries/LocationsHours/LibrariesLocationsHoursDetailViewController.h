#import <UIKit/UIKit.h>
#import "LibrariesLocationsHours.h"

typedef enum {
    LibrariesDetailStatusLoaded,
    LibrariesDetailStatusLoading,
    LibrariesDetailStatusLoadingFailed
} LibrariesDetailStatus;

@interface LibrariesLocationsHoursDetailViewController : UIViewController <UIWebViewDelegate> {
    
}

@property (nonatomic, strong) UITableView *tableView;
@property (retain, nonatomic) LibrariesLocationsHours *library;
@property (nonatomic) LibrariesDetailStatus librariesDetailStatus;
@property (nonatomic) CGFloat contentRowHeight;
@property (retain, nonatomic) UIWebView *contentWebView;

@end
