#import "MITLauncherListViewCell.h"
#import "MITModule.h"

@implementation MITLauncherListViewCell
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
    
    self.moduleImageView.image = module.springboardIcon;
    
    if (self.shouldUseShortModuleNames) {
        self.moduleNameLabel.text = module.shortName;
    } else {
        self.moduleNameLabel.text = module.longName;
    }
}

@end
