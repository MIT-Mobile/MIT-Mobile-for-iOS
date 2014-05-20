#import <UIKit/UIKit.h>

@class MITShuttleStop;

typedef enum {
    MITShuttleStopCellTypeRouteList,
    MITShuttleStopCellTypeRouteDetail
} MITShuttleStopCellType;

@interface MITShuttleStopCell : UITableViewCell

- (void)setCellType:(MITShuttleStopCellType)cellType;
- (void)setStop:(MITShuttleStop *)stop;

@end
