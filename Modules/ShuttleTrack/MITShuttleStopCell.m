#import "MITShuttleStopCell.h"
#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"
#import "UIKit+MITAdditions.h"

const CGFloat kStopCellDefaultSeparatorLeftInset = 42.0;

NSString * const kMITShuttleStopCellNibName = @"MITShuttleStopCell";
NSString * const kMITShuttleStopCellIdentifier = @"MITShuttleStopCell";

static NSString * const kTimeUnavailableText = @"--";

@interface MITShuttleStopCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *routeIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *routeIndicatorCircleView;

@end

@implementation MITShuttleStopCell

- (void)awakeFromNib
{
    self.routeIndicatorCircleView.layer.cornerRadius = self.routeIndicatorCircleView.frame.size.width / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCellType:(MITShuttleStopCellType)cellType
{
    self.routeIndicatorView.hidden = (cellType == MITShuttleStopCellTypeRouteList);
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

- (void)setIsNextStop:(BOOL)isNextStop
{
    self.routeIndicatorCircleView.backgroundColor = isNextStop ? [UIColor mit_tintColor] : [UIColor colorWithWhite:0.8 alpha:1.0];
}

@end
