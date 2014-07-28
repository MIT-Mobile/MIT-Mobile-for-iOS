#import "MITEventDetailCell.h"
#import "UIKit+MITAdditions.h"

@interface MITEventDetailCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UIButton *iconActionButton;

@end

@implementation MITEventDetailCell

- (void)awakeFromNib
{
    // Initialization code
    self.titleLabel.textColor = [UIColor mit_tintColor];
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
