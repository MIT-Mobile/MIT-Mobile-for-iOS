#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttlePrediction;

typedef enum {
    MITShuttleStopCellTypeRouteList,
    MITShuttleStopCellTypeRouteDetail
} MITShuttleStopCellType;

extern const CGFloat kStopCellDefaultSeparatorLeftInset;

@interface MITShuttleStopCell : UITableViewCell

- (void)setCellType:(MITShuttleStopCellType)cellType;
- (void)setStop:(MITShuttleStop *)stop prediction:(MITShuttlePrediction *)prediction;

@end
