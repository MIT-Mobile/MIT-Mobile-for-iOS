#import "MITMobiusResourceView.h"
#import "MITAdditions.h"

@implementation MITMobiusResourceView
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _index = NSNotFound;
        [self _refreshContent];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _index = NSNotFound;
        [self _refreshContent];
    }
    
    return self;
}

- (void)setIndex:(NSUInteger)index
{
    if (_index != index) {
        _index = index;
        [self _refreshContent];
    }
}

- (void)setMachineName:(NSString *)machineName
{
    if (![_machineName isEqualToString:machineName]) {
        _machineName = [machineName copy];
        [self _refreshContent];
    }
}

- (void)_refreshContent
{
    NSString *machineName = nil;
    if (self.index == NSNotFound) {
        machineName = self.machineName;
    } else {
        machineName = [NSString stringWithFormat:@"%lu. %@",(unsigned long)self.index,self.machineName];
    }
    
    self.machineNameLabel.text = machineName;
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.machineNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.machineNameLabel.bounds);
}

@end
