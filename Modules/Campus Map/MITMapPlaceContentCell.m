#import "MITMapPlaceContentCell.h"
#import "MITMapPlaceContent.h"

@interface MITMapPlaceContentCell()

@property (nonatomic, weak) IBOutlet UILabel *placeContentNameLabel;

@end

@implementation MITMapPlaceContentCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.placeContentNameLabel.preferredMaxLayoutWidth = self.placeContentNameLabel.bounds.size.width;
}

#pragma mark - Public Methods

- (void)setPlaceContent:(MITMapPlaceContent *)placeContent
{
    self.placeContentNameLabel.text = placeContent.name;
}

@end
