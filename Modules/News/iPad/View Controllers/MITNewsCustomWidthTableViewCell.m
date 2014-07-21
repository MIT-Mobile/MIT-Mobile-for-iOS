#import "MITNewsCustomWidthTableViewCell.h"

static NSUInteger maximumWidthOfTable = 648;

@implementation MITNewsCustomWidthTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFrame:(CGRect)frame {
    if (frame.size.width > maximumWidthOfTable) {
        frame.origin.x += (frame.size.width - maximumWidthOfTable) / 2;
        frame.size.width = maximumWidthOfTable;
    }
    [super setFrame:frame];
}

@end
