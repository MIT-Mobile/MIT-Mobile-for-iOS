#import "MITLauncherGridViewCell.h"
#import "MITModule.h"

@implementation MITLauncherGridViewCell
- (void)awakeFromNib
{
    
}

- (void)setShouldUseShortModuleNames:(BOOL)shouldUseShortModuleNames
{
    if (_shouldUseShortModuleNames != shouldUseShortModuleNames) {
        _shouldUseShortModuleNames = shouldUseShortModuleNames;

        if (_module) {
            // if the value of shouldUseShortModuleNames changed and a module has
            // already been set, we need to force an update to the UI so the change is reflected
            [self setModule:_module];
            [self.contentView setNeedsLayout];
            [self.contentView setNeedsDisplay];
        }
    }
}

- (void)setModule:(MITModule *)module
{
    _module = module;
    
    self.imageView.image = module.springboardIcon;

    if (self.shouldUseShortModuleNames) {
        self.titleLabel.text = module.shortName;
    } else {
        self.titleLabel.text = module.longName;
    }
}

@end
