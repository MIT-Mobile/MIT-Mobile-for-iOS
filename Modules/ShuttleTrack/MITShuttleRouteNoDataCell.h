#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString * const kMITShuttleRouteNoDataCellNibName;

@class MITShuttleRoute;

@interface MITShuttleRouteNoDataCell : UITableViewCell

- (void)setNoPredictions:(MITShuttleRoute *)route;
- (void)setNotInService:(MITShuttleRoute *)route;

@end
