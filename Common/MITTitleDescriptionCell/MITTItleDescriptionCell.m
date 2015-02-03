#import "MITTitleDescriptionCell.h"

@interface MITTitleDescriptionCell()

@property (weak, nonatomic) IBOutlet UILabel *titleTextView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTextView;

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
    self.titleTextView.text = title;
    self.descriptionTextView.text = description;
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titleTextView.preferredMaxLayoutWidth = self.titleTextView.bounds.size.width;
    self.descriptionTextView.preferredMaxLayoutWidth = self.descriptionTextView.bounds.size.width;
}

@end
