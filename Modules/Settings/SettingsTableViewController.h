#import <UIKit/UIKit.h>
#import "MITModule.h"

@interface SettingsTableViewController : UITableViewController {

    NSArray *_notifications;
    NSDictionary *_pushServers;
    UIGestureRecognizer *_showAdvancedGesture;
    UIGestureRecognizer *_hideAdvancedGesture;
    BOOL                _advancedOptionsVisible;
    NSUInteger          _selectedRow;
}

- (void)switchDidToggle:(id)sender;
- (void)reloadSettings;

@property (nonatomic, retain) NSArray *notifications;
@property (nonatomic, retain) NSMutableDictionary *apiRequests;

@end
