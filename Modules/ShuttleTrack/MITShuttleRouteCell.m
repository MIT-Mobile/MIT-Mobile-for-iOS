#import "MITShuttleRouteCell.h"
#import "MITShuttleRoute.h"

NSString * const kMITShuttleRouteCellNibName = @"MITShuttleRouteCell";
NSString * const kMITShuttleRouteCellIdentifier = @"MITShuttleRouteCell";

static const CGFloat kCellHeightNoAlert = 45.0;

static const UILayoutPriority kAlertContainerViewHeightConstraintPriorityHidden = 1000;

@interface MITShuttleRouteCell()

@property (weak, nonatomic) IBOutlet UIImageView *statusIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *alertIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alertContainerViewHeightConstraint;

@end

@implementation MITShuttleRouteCell

- (void)awakeFromNib
{
    self.alertContainerViewHeightConstraint.priority = kAlertContainerViewHeightConstraintPriorityHidden;
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
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesRouteNotInService];
            break;
        case MITShuttleRouteStatusInService:
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesRouteInService];
            break;
        case MITShuttleRouteStatusPredictionsUnavailable:
            self.statusIconImageView.image = [UIImage imageNamed:MITImageShuttlesRoutePredictionsUnavailable];
            break;
        default:
            break;
    }
    self.nameLabel.text = route.title;
}

+ (CGFloat)cellHeightForRoute:(MITShuttleRoute *)route
{
#warning TODO: check alert and use appropriate cell height
    return kCellHeightNoAlert;
}

@end
