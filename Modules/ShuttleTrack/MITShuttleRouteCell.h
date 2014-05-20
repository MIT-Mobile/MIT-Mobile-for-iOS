#import <UIKit/UIKit.h>

@class MITShuttleRoute;

@interface MITShuttleRouteCell : UITableViewCell

- (void)setRoute:(MITShuttleRoute *)route;

+ (CGFloat)cellHeightForRoute:(MITShuttleRoute *)route;

@end
