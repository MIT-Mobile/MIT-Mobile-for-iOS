#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStopNotificationManager.h"

@interface MITShuttleStopAlarmCell ()

@property (nonatomic, weak) IBOutlet UILabel *timeRemainingLabel;
@property (nonatomic, weak) IBOutlet UILabel *clockTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *alertButton;

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
        self.clockTimeLabel.text = @"";
        
        return;
    }
    
    NSInteger minutesLeft = floor([prediction.seconds doubleValue] / 60);
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"%im", minutesLeft];
    
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
    self.clockTimeLabel.text = [formatter stringFromDate:predictionDate];
    
    [self updateNotificationButtonWithPrediction:prediction];
}

- (void)updateNotificationButtonWithPrediction:(MITShuttlePrediction *)prediction
{
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
    UILocalNotification *scheduledNotification = [[MITShuttleStopNotificationManager sharedManager] notificationForPrediction:prediction];
    if (scheduledNotification) {
        [self.alertButton setImage:[UIImage imageNamed:MITImageShuttlesAlertOn] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
    } else if ([predictionDate timeIntervalSinceDate:[NSDate date]] < 305) { // No sense in letting a user schedule a notification if it's only going to fire immediately
        self.alertButton.hidden = YES;
    } else {
        [self.alertButton setImage:[UIImage imageNamed:MITImageShuttlesAlertOn] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
    }
}

@end
