#import "MITEventDetailCell.h"
#import "UIKit+MITAdditions.h"

@interface MITEventDetailCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UIButton *iconActionButton;
@property (nonatomic, weak) IBOutlet UIView *separatorView;

@end

@implementation MITEventDetailCell

- (void)awakeFromNib
{
    [super awakeFromNib];
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

#pragma mark - Public Methods

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)setDetailText:(NSString *)detailText
{
    self.detailsLabel.text = detailText;
}

- (void)setIconForRowType:(MITEventDetailRowType)rowType
{
//    switch (rowType) {
//        case MITEventDetailRowTypeLocation:
//            <#statements#>
//            break;
//            
//        default:
//            break;
//    }
}

@end
