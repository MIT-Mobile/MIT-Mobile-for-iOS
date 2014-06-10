#import <UIKit/UIKit.h>

@class MITShuttleStop;
@class MITShuttlePrediction;

@interface MITShuttleStopAlarmCell : UITableViewCell

- (void)updateUIWithPrediction:(MITShuttlePrediction *)prediction atStop:(MITShuttleStop *)stop;

@end
