#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStopNotificationManager.h"
#import "UIKit+MITAdditions.h"

@interface MITShuttleStopAlarmCell ()

@property (nonatomic, weak) IBOutlet UILabel *timeRemainingLabel;
@property (nonatomic, weak) IBOutlet UIButton *alertButton;
@property (weak, nonatomic) IBOutlet UILabel *alarmSetLabel;

- (IBAction)notificationButtonPressed:(id)sender;

@end

@implementation MITShuttleStopAlarmCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)notificationButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(stopAlarmCellDidToggleAlarm:)]) {
        [self.delegate stopAlarmCellDidToggleAlarm:self];
    }
}

- (void)updateUIWithPrediction:(MITShuttlePrediction *)prediction
{
    if (!prediction) {
        self.timeRemainingLabel.text = @"";
        return;
    }
    
    NSInteger minutesLeft = floor([prediction.seconds doubleValue] / 60);
    if (minutesLeft < 1) {
        self.timeRemainingLabel.text = @"now";
        self.timeRemainingLabel.textColor = [UIColor mit_tintColor];
    } else {
        self.timeRemainingLabel.text = [NSString stringWithFormat:@"%im", minutesLeft];
        self.timeRemainingLabel.textColor = [UIColor darkTextColor];
    }
    
    [self updateNotificationButtonWithPrediction:prediction];
}

- (void)updateNotificationButtonWithPrediction:(MITShuttlePrediction *)prediction
{
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
    UILocalNotification *scheduledNotification = [[MITShuttleStopNotificationManager sharedManager] notificationForPrediction:prediction];
    if (scheduledNotification) {
        [self.alertButton setImage:[UIImage imageNamed:@"shuttle/shuttlesAlarmOn"] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
        self.alarmSetLabel.hidden = NO;
    } else if ([predictionDate timeIntervalSinceDate:[NSDate date]] < 305) { // No sense in letting a user schedule a notification if it's only going to fire immediately
        self.alertButton.hidden = YES;
        self.alarmSetLabel.hidden = YES;
    } else {
        [self.alertButton setImage:[UIImage imageNamed:@"shuttle/shuttlesAlarmOff"] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
        self.alarmSetLabel.hidden = YES;
    }
}

@end
