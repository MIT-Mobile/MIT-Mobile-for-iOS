#import "MITShuttleRouteStatusCell.h"
#import "MITShuttleRoute.h"

@interface MITShuttleRouteStatusCell()

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusIconImageView;

@end

@implementation MITShuttleRouteStatusCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.descriptionLabel.preferredMaxLayoutWidth = self.descriptionLabel.bounds.size.width;
}

- (void)setRoute:(MITShuttleRoute *)route
{
    switch ([route status]) {
        case MITShuttleRouteStatusNotInService:
            self.statusLabel.text = @"Not in service";
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesNotInServiceSmall];
            break;
        case MITShuttleRouteStatusInService:
            self.statusLabel.text = @"In service";
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesInServiceSmall];
            break;
        case MITShuttleRouteStatusUnknown:
            self.statusLabel.text = @"No current predictions";
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesUnknownSmall];
            break;
        default:
            break;
    }
    self.descriptionLabel.text = route.routeDescription;
}

@end
