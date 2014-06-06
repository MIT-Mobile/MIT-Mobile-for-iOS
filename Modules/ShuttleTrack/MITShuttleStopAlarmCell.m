#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleStopNotificationManager.h"

NSString * const kMITShuttleStopAlarmCellNibName = @"MITShuttleStopAlarmCell";

@interface MITShuttleStopAlarmCell ()

@property (nonatomic, strong) MITShuttlePrediction *prediction;
@property (nonatomic, strong) MITShuttleStop *stop;
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
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[self.prediction.timestamp doubleValue]];
    UILocalNotification *scheduledNotification = [[MITShuttleStopNotificationManager sharedManager] notificationForStop:self.stop nearTime:predictionDate];
    if (scheduledNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:scheduledNotification];
    } else {
        // Use 10 minutes variance. Using the length of the route loop isn't accurate since there can be multiple shuttles on a route. 10 minutes is a "best-guess" scenario unless we can find a better way or add support in the api
        [[MITShuttleStopNotificationManager sharedManager] scheduleNotificationForStop:self.stop fromPredictionTime:predictionDate withVariance:600];
    }
    
    [self updateNotificationButton];
}

- (void)updateUIWithPrediction:(MITShuttlePrediction *)prediction atStop:(MITShuttleStop *)stop
{
    self.prediction = prediction;
    self.stop = stop;
    
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
    
    [self updateNotificationButton];
}

- (void)updateNotificationButton
{
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[self.prediction.timestamp doubleValue]];
    UILocalNotification *scheduledNotification = [[MITShuttleStopNotificationManager sharedManager] notificationForStop:self.stop nearTime:predictionDate];
    if (scheduledNotification) {
        [self.alertButton setImage:[UIImage imageNamed:@"shuttle/shuttle-alert-toggle-on"] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
    } else if ([predictionDate timeIntervalSinceDate:[NSDate date]] < 305) { // No sense in letting a user schedule a notification if it's only going to fire immediately
        self.alertButton.hidden = YES;
    } else {
        [self.alertButton setImage:[UIImage imageNamed:@"shuttle/shuttle-alert-toggle-off"] forState:UIControlStateNormal];
        self.alertButton.hidden = NO;
    }
}

@end
