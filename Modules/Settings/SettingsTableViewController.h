#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITModule.h"

@interface SettingsTableViewController : UITableViewController <JSONLoadedDelegate> {

    NSArray *notifications;
	NSMutableDictionary *apiRequests;
	
}

- (void)switchDidToggle:(id)sender;
- (void)reloadSettings;

@property (nonatomic, retain) NSArray *notifications;
@property (nonatomic, retain) NSMutableDictionary *apiRequests;

@end
