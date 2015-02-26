#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

@protocol MITShuttleHomeViewControllerDelegate;

@interface MITShuttleHomeViewController : UITableViewController

@property (nonatomic, weak) id <MITShuttleHomeViewControllerDelegate> delegate;

- (void)highlightStop:(MITShuttleStop *)stop;

@end

@protocol MITShuttleHomeViewControllerDelegate <NSObject>

@optional
- (void)shuttleHomeViewController:(MITShuttleHomeViewController *)viewController didSelectRoute:(MITShuttleRoute *)route stop:(MITShuttleStop *)stop;

@end
