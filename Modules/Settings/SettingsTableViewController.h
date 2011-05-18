#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITModule.h"

@interface SettingsTableViewController : UITableViewController <JSONLoadedDelegate> {

    NSArray *_notifications;
    NSDictionary *_pushServers;
	NSMutableDictionary *_apiRequests;
    UIGestureRecognizer *_showAdvancedGesture;
    UIGestureRecognizer *_hideAdvancedGesture;
    BOOL                _advancedOptionsVisible;
    NSUInteger          _selectedRow;
    
    dispatch_queue_t _requestQueue;
}

- (void)switchDidToggle:(id)sender;
- (void)reloadSettings;

@property (nonatomic, retain) NSArray *notifications;
@property (nonatomic, retain) NSMutableDictionary *apiRequests;

@end
