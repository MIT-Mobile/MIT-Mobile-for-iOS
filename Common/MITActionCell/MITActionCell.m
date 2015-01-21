#import "MITActionCell.h"
#import "UIKit+MITAdditions.h"

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

- (void)setupCellOfType:(MITEventDetailRowType)type withDetailText:(NSString *)detailText
{
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    switch (type) {
        case MITEventDetailRowTypeSpeaker: {
            [self setTitle:@"speaker"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeTime: {
            [self setTitle:@"time"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewCalendar];
            break;
        }
        case MITEventDetailRowTypeLocation: {
            [self setTitle:@"location"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
            break;
        }
        case MITEventDetailRowTypePhone: {
            [self setTitle:@"phone"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
            break;
        }
        case MITEventDetailRowTypeDescription: {
            // Special case, handled by webview cell
            break;
        }
        case MITEventDetailRowTypeWebsite: {
            [self setTitle:@"website"];
            [self setDetailText:detailText];
            self.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
            break;
        }
        case MITEventDetailRowTypeOpenTo: {
            [self setTitle:@"open to"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeCost: {
            [self setTitle:@"cost"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeSponsors: {
            [self setTitle:@"sponsor"];
            [self setDetailText:detailText];
            self.accessoryView = nil;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case MITEventDetailRowTypeContact: {
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
