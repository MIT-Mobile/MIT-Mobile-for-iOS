#import <UIKit/UIKit.h>
#import "LibrariesLocationsHours.h"

typedef NS_ENUM(NSInteger, LibrariesDetailStatus) {
    LibrariesDetailStatusLoaded = 0,
    LibrariesDetailStatusLoading,
    LibrariesDetailStatusLoadingFailed
};

@interface LibrariesLocationsHoursDetailViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIWebView *contentWebView;
@property (nonatomic, strong) LibrariesLocationsHours *library;
@property LibrariesDetailStatus librariesDetailStatus;
@property CGFloat contentRowHeight;
@end
