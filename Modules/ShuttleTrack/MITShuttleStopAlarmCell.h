#import <UIKit/UIKit.h>

@class MITShuttlePrediction;

@protocol MITShuttleStopAlarmCellDelegate;

@interface MITShuttleStopAlarmCell : UITableViewCell

@property (nonatomic, weak) id <MITShuttleStopAlarmCellDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIButton *alertButton;

- (void)updateUIWithPrediction:(MITShuttlePrediction *)prediction;
- (void)updateNotificationButtonWithPrediction:(MITShuttlePrediction *)prediction;

@end

@protocol MITShuttleStopAlarmCellDelegate <NSObject>

- (void)stopAlarmCellDidToggleAlarm:(MITShuttleStopAlarmCell *)cell;

@end
