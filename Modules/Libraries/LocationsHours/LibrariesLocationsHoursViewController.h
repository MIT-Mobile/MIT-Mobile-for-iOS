#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"

@interface LibrariesLocationsHoursViewController : UITableViewController <JSONLoadedDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, retain) NSArray *libraries;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) MITMobileWebAPI *request;
@end
