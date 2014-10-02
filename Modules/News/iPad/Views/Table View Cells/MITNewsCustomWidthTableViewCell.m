#import "MITNewsCustomWidthTableViewCell.h"

static CGFloat maximumWidthOfTable = 648;

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

- (void)setFrame:(CGRect)frame
{
    CGFloat width = self.superview.frame.size.width;
    if (width > maximumWidthOfTable) {
        CGFloat padding = (width - maximumWidthOfTable) / 2;
        if (padding != frame.origin.x) {
            frame.origin.x += padding;
        } else {
            frame.origin.x = padding;
        }
        frame.size.width = maximumWidthOfTable;
    }
    
    [super setFrame:frame];
}

@end
