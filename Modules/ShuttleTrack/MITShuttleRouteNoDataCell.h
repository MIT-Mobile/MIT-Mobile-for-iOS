#import <UIKit/UIKit.h>

@class MITShuttleRoute;

@interface MITShuttleRouteNoDataCell : UITableViewCell

- (void)setNoPredictions:(MITShuttleRoute *)route;
- (void)setNotInService:(MITShuttleRoute *)route;

@end
