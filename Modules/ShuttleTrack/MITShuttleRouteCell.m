#import "MITShuttleRouteCell.h"
#import "MITShuttleRoute.h"

NSString * const kMITShuttleRouteCellNibName = @"MITShuttleRouteCell";
NSString * const kMITShuttleRouteCellIdentifier = @"MITShuttleRouteCell";

@interface MITShuttleRouteCell()

@property (weak, nonatomic) IBOutlet UIImageView *statusIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation MITShuttleRouteCell

- (void)awakeFromNib
{
    self.textLabel.font = [UIFont systemFontOfSize:17.0];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setRoute:(MITShuttleRoute *)route
{
    switch ([route status]) {
        case MITShuttleRouteStatusNotInService:
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesNotInService];
            break;
        case MITShuttleRouteStatusInService:
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesInService];
            break;
        case MITShuttleRouteStatusUnknown:
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesUnknown];
            break;
        default:
            break;
    }
    self.nameLabel.text = route.title;
}

@end
