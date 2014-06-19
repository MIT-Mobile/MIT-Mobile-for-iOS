#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttlePrediction;

extern const CGFloat kStopCellDefaultSeparatorLeftInset;

extern NSString * const kMITShuttleStopCellNibName;
extern NSString * const kMITShuttleStopCellIdentifier;

typedef NS_ENUM(NSUInteger, MITShuttleStopCellType) {
    MITShuttleStopCellTypeRouteList,
    MITShuttleStopCellTypeRouteDetail
};

@interface MITShuttleStopCell : UITableViewCell

- (void)setCellType:(MITShuttleStopCellType)cellType;
- (void)setStop:(MITShuttleStop *)stop prediction:(MITShuttlePrediction *)prediction;
- (void)setIsNextStop:(BOOL)isNextStop;

@end
