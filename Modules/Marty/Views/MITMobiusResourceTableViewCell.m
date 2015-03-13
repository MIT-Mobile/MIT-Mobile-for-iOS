#import "MITMobiusResourceTableViewCell.h"
#import "MITMartyModel.h"
#import "UIKit+MITAdditions.h"
#import "MITMobiusResourceView.h"

@interface MITMobiusResourceTableViewCell ()

@end

@implementation MITMobiusResourceTableViewCell

- (void)awakeFromNib {
    self.resourceView.index = NSNotFound;
}

- (void)prepareForReuse
{
    self.resourceView.index = NSNotFound;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
