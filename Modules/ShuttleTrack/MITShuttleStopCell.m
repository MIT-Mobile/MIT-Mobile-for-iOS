#import "MITShuttleStopCell.h"
#import "MITShuttleStop.h"

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

- (void)setStop:(MITShuttleStop *)stop
{
    self.nameLabel.text = stop.title;
    self.timeLabel.text = kTimeUnavailableText;
}

@end
