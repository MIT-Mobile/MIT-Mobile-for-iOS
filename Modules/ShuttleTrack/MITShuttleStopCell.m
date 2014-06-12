#import "MITShuttleStopCell.h"
#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"

const CGFloat kStopCellDefaultSeparatorLeftInset = 42.0;

static NSString * const kTimeUnavailableText = @"--";

@interface MITShuttleStopCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *routeIndicatorImageView;

@end

@implementation MITShuttleStopCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellType:(MITShuttleStopCellType)cellType
{
    self.routeIndicatorImageView.hidden = (cellType == MITShuttleStopCellTypeRouteList);
}

- (void)setStop:(MITShuttleStop *)stop prediction:(MITShuttlePrediction *)prediction
{
    self.nameLabel.text = stop.title;
    if (prediction) {
        NSInteger minutes = floor([prediction.seconds doubleValue] / 60);
        self.timeLabel.text = [NSString stringWithFormat:@"%dm", minutes];
    } else {
        self.timeLabel.text = kTimeUnavailableText;
    }
}

@end
