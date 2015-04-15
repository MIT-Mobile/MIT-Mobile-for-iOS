#import "MITMobiusQuickSearchHeaderTableViewCell.h"

@implementation MITMobiusQuickSearchHeaderTableViewCell

- (void)awakeFromNib
{
}

+ (UINib *)quickSearchHeaderCellNib
{
    return [UINib nibWithNibName:self.quickSearchHeaderCellNibName bundle:nil];
}

+ (NSString *)quickSearchHeaderCellNibName
{
    return @"MITMobiusQuickSearchHeaderTableViewCell";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
