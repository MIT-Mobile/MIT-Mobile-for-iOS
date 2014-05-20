//
//  MITShuttleStopAlarmCell.m
//  MIT Mobile
//
//  Created by Ross LeBeau on 5/27/14.
//
//

#import "MITShuttleStopAlarmCell.h"
#import "MITShuttlePrediction.h"

NSString * const kMITShuttleStopAlarmCellNibName = @"MITShuttleStopAlarmCell";

@interface MITShuttleStopAlarmCell ()

@property (nonatomic, weak) IBOutlet UILabel *timeRemainingLabel;
@property (nonatomic, weak) IBOutlet UILabel *clockTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *alertButton;

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

//- (NSDateFormatter)

- (void)setPrediction:(MITShuttlePrediction *)prediction
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
//        [formatter setDateFormat:[[NSCalendar currentCalendar] dateFormat]];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    NSDate *predictionDate = [NSDate dateWithTimeIntervalSince1970:[prediction.timestamp doubleValue]];
    self.clockTimeLabel.text = [formatter stringFromDate:predictionDate];
    
    NSLog(@"timestamp: %@, date: %@", prediction.timestamp, predictionDate);
}

- (void)setNotInService
{
    self.timeRemainingLabel.text = @"";
    self.clockTimeLabel.text = @"";
}

@end
