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
            self.statusIconImageView.image = [UIImage imageNamed:@"shuttle/shuttle-off"];
            break;
        case MITShuttleRouteStatusInService:
            self.statusLabel.text = @"In service";
            self.statusIconImageView.image = [UIImage imageNamed:@"shuttle/shuttle"];
            break;
        case MITShuttleRouteStatusPredictionsUnavailable:
            self.statusLabel.text = @"Predictions unavailable";
#warning TODO: question mark image
            self.statusIconImageView.image = [UIImage imageNamed:@""];
            break;
        default:
            break;
    }
    self.descriptionLabel.text = route.routeDescription;
}

@end
