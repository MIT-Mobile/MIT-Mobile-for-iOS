#import "MITMobiusQuickSearchTableViewCell.h"

@implementation MITMobiusQuickSearchTableViewCell

- (void)awakeFromNib
{
}

+ (UINib *)quickSearchCellNib
{
    return [UINib nibWithNibName:self.quickSearchCellNibName bundle:nil];
}

+ (NSString *)quickSearchCellNibName
{
    return @"MITMobiusQuickSearchTableViewCell";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
