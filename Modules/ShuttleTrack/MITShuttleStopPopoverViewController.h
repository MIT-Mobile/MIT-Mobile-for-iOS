#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttleRoute;

@interface MITShuttleStopPopoverViewController : UIViewController

@property (nonatomic, strong) MITShuttleStop *stop;
@property (nonatomic, strong) MITShuttleRoute *currentRoute;

- (instancetype)initWithStop:(MITShuttleStop *)stop route:(MITShuttleRoute *)route;

@end
