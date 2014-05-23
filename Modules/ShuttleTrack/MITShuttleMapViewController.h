#import <UIKit/UIKit.h>

@class MITShuttleRoute;
@class MITShuttleStop;

@interface MITShuttleMapViewController : UIViewController

- (instancetype)initWithRoute:(MITShuttleRoute *)route;

@property (strong, nonatomic) MITShuttleRoute *route;
@property (strong, nonatomic) MITShuttleStop *stop;

@end
