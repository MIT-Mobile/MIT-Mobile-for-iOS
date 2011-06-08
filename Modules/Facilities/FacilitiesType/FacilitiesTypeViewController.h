#import <UIKit/UIKit.h>
#import "MITLoadingActivityView.h"
#import "MITMobileWebAPI.h"

@interface FacilitiesTypeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, JSONLoadedDelegate>
{
    NSDictionary *_userData;
    UITableView *_tableView;
    MITLoadingActivityView *_loadingView;
}

@property (nonatomic,copy) NSDictionary *userData;
@property (nonatomic,retain) UITableView* tableView;
@property (nonatomic, retain) MITLoadingActivityView *loadingView;

- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject;
- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error;
@end
