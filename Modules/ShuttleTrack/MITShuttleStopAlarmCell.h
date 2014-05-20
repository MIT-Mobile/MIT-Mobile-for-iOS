#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString * const kMITShuttleStopAlarmCellNibName;

@class MITShuttleStop;
@class MITShuttlePrediction;

@interface MITShuttleStopAlarmCell : UITableViewCell

- (void)setPrediction:(MITShuttlePrediction *)prediction;
- (void)setNotInService;

@end
