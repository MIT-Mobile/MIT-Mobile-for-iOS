#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttleRoute;

@protocol MITShuttleStopPopoverViewControllerDelegate;

@interface MITShuttleStopPopoverViewController : UIViewController

@property (nonatomic, strong) MITShuttleStop *stop;
@property (nonatomic, strong) MITShuttleRoute *currentRoute;
@property (nonatomic, weak) id <MITShuttleStopPopoverViewControllerDelegate> delegate;

- (instancetype)initWithStop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route;

@end

@protocol MITShuttleStopPopoverViewControllerDelegate <NSObject>

- (void)stopPopoverViewController:(MITShuttleStopPopoverViewController *)viewController didScrollToRoute:(MITShuttleRoute *)route;
- (void)stopPopoverViewController:(MITShuttleStopPopoverViewController *)viewController didSelectRoute:(MITShuttleRoute *)route;

@end
