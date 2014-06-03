#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString * const kMITShuttleStopAlarmCellNibName;

@class MITShuttleStop;
@class MITShuttlePrediction;

@interface MITShuttleStopAlarmCell : UITableViewCell

- (void)updateUIWithPrediction:(MITShuttlePrediction *)prediction atStop:(MITShuttleStop *)stop;

@end
