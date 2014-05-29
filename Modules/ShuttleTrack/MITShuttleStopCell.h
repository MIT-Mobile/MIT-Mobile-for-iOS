#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttlePrediction;

extern NSString * const kMITShuttleStopCellNibName;
extern NSString * const kMITShuttleStopCellIdentifier;

typedef enum {
    MITShuttleStopCellTypeRouteList,
    MITShuttleStopCellTypeRouteDetail
} MITShuttleStopCellType;

@interface MITShuttleStopCell : UITableViewCell

- (void)setCellType:(MITShuttleStopCellType)cellType;
- (void)setStop:(MITShuttleStop *)stop prediction:(MITShuttlePrediction *)prediction;
- (void)setIsNextStop:(BOOL)isNextStop;

@end
