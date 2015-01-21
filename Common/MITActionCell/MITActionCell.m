#import "MITActionCell.h"
#import "UIKit+MITAdditions.h"
#import "MITConstants.h"

@interface MITActionCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UIButton *iconActionButton;
@property (nonatomic, weak) IBOutlet UIView *separatorView;

@end

@implementation MITActionCell

- (void)awakeFromNib
{
    // Initialization code
    self.titleLabel.textColor = [UIColor mit_tintColor];
    self.iconActionButton.backgroundColor = [UIColor greenColor];
}

+ (UINib *)actionCellNib
{
    return [UINib nibWithNibName:self.actionCellNibName bundle:nil];
}

+ (NSString *)actionCellNibName {
    return @"MITActionCell";
}

+ (NSString *)actionCellIdentifier {
    return @"MITActionCellIdentifier";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.detailsLabel.preferredMaxLayoutWidth = self.detailsLabel.bounds.size.width;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupCellOfType:(MITActionRowType)type withDetailText:(NSString *)detailText
{
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    switch (type) {
        case MITActionRowTypeSpeaker: {
            [self setTitle:@"speaker"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITActionRowTypeTime: {
            [self setTitle:@"time"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
            break;
        }
        case MITActionRowTypeLocation: {
            [self setTitle:@"location"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            break;
        }
        case MITActionRowTypePhone: {
            [self setTitle:@"phone"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            break;
        }
        case MITActionRowTypeDescription: {
            // Special case, handled by webview cell
            break;
        }
        case MITActionRowTypeWebsite: {
            [self setTitle:@"website"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            break;
        }
        case MITActionRowTypeOpenTo: {
            [self setTitle:@"open to"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITActionRowTypeCost: {
            [self setTitle:@"cost"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITActionRowTypeSponsors: {
            [self setTitle:@"sponsor"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITActionRowTypeContact: {
            [self setTitle:@"for more information, contact"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewEmail];
            break;
        }
    }
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

#pragma mark - Public Methods

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)setDetailText:(NSString *)detailText
{
    self.detailsLabel.text = detailText;
}

@end
