#import <UIKit/UIKit.h>
#import "LibrariesLocationsHours.h"
#import "MITMobileWebAPI.h"

typedef enum {
    LibrariesDetailStatusLoaded,
    LibrariesDetailStatusLoading,
    LibrariesDetailStatusLoadingFailed
} LibrariesDetailStatus;

@interface LibrariesLocationsHoursDetailViewController : UITableViewController <JSONLoadedDelegate> {
    
}

@property (retain, nonatomic) LibrariesLocationsHours *library;
@property (retain, nonatomic) MITMobileWebAPI *request;
@property (nonatomic) LibrariesDetailStatus librariesDetailStatus;

@end
