#import "MITShuttleStopCell.h"
#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"
#import "UIKit+MITAdditions.h"

const CGFloat kStopCellDefaultSeparatorLeftInset = 44.0;

NSString * const kMITShuttleStopCellNibName = @"MITShuttleStopCell";
NSString * const kMITShuttleStopCellIdentifier = @"MITShuttleStopCell";

static NSString * const kTimeUnavailableText = @"—";

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
    self.backgroundColor = selected ? [UIColor colorWithWhite:0.9 alpha:1.0] : [UIColor whiteColor];
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
        if (minutes > 0) {
            self.timeLabel.text = [NSString stringWithFormat:@"%ldm", (long)minutes];
            self.timeLabel.textColor = [UIColor darkTextColor];
        } else {
            self.timeLabel.text = @"now";
            self.timeLabel.textColor = [UIColor mit_tintColor];
        }
    } else {
        self.timeLabel.text = kTimeUnavailableText;
        self.timeLabel.textColor = [UIColor darkTextColor];
    }
}

- (void)setIsNextStop:(BOOL)isNextStop
{
    self.routeIndicatorCircleView.backgroundColor = isNextStop ? [UIColor mit_tintColor] : [UIColor colorWithWhite:0.8 alpha:1.0];
}

@end
