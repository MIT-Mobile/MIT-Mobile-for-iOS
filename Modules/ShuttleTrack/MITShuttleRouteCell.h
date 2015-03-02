#import <UIKit/UIKit.h>

@class MITShuttleRoute;

extern NSString * const kMITShuttleRouteCellNibName;
extern NSString * const kMITShuttleRouteCellIdentifier;

@interface MITShuttleRouteCell : UITableViewCell

- (void)setRoute:(MITShuttleRoute *)route;

@end
