#import "MITTitleDescriptionCell.h"

@interface MITTitleDescriptionCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation MITTitleDescriptionCell

- (void)awakeFromNib
{
    // Initialization code
}

+ (UINib *)titleDescriptionCellNib
{
    return [UINib nibWithNibName:self.titleDescriptionCellNibName bundle:nil];
}

+ (NSString *)titleDescriptionCellNibName
{
    return @"MITTitleDescriptionCell";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title withDescription:(NSString *)description
{    
    self.titleLabel.text = title;
    self.descriptionLabel.text = description;
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.titleLabel.preferredMaxLayoutWidth < CGRectGetWidth(self.titleLabel.bounds)) {
        self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.bounds.size.width;
        
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
    }
    
    if (self.descriptionLabel.preferredMaxLayoutWidth < CGRectGetWidth(self.descriptionLabel.bounds)) {
        self.descriptionLabel.preferredMaxLayoutWidth = self.descriptionLabel.bounds.size.width;
        
        [self setNeedsUpdateConstraints];
        [self setNeedsLayout];
    }

    [self layoutIfNeeded];
}

@end
