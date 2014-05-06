#import "MITLauncherViewCell.h"
#import "MITModule.h"

@implementation MITLauncherViewCell
- (void)awakeFromNib
{
    
}

- (void)setModule:(MITModule *)module
{
    _module = module;
    
    self.imageView.image = module.springboardIcon;
    self.titleLabel.text = module.longName;
}

@end
