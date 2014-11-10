#import "MITShuttleRouteNoDataCell.h"
#import "MITShuttleRoute.h"

@interface MITShuttleRouteNoDataCell ()

@property (nonatomic, weak) IBOutlet UIImageView *leftImageView;
@property (nonatomic, weak) IBOutlet UILabel *mainLabel;

@end

@implementation MITShuttleRouteNoDataCell

- (void)awakeFromNib
{
    self.mainLabel.preferredMaxLayoutWidth = self.mainLabel.frame.size.width;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Public Methods

- (void)setNoPredictions:(MITShuttleRoute *)route
{
    self.leftImageView.image = [UIImage imageNamed:MITImageShuttlesRoutePredictionsUnavailable];
    self.mainLabel.text = route.routeDescription;
}

- (void)setNotInService:(MITShuttleRoute *)route
{
    self.leftImageView.image = [UIImage imageNamed:MITImageShuttlesRouteNotInService];
    self.mainLabel.text = route.routeDescription;
}

@end
