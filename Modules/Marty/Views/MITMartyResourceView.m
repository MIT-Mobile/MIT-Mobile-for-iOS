#import "MITMartyResourceView.h"
#import "MITAdditions.h"

@implementation MITMartyResourceView
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

- (void)setLocation:(NSString *)location
{
    if (![_location isEqualToString:location]) {
        _location = [location copy];
        
        [self _refreshContent];
    }
}

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString *)statusText
{
    self.statusLabel.text = [statusText copy];
    
    switch (status) {
        case MITMartyResourceStatusOffline: {
            self.statusLabel.textColor = [UIColor mit_closedRedColor];
        } break;
            
        case MITMartyResourceStatusOnline: {
            self.statusLabel.textColor = [UIColor mit_openGreenColor];
        } break;
            
        case MITMartyResourceStatusUnknown: {
            self.statusLabel.textColor = [UIColor orangeColor];
        } break;
    }
    
    [self _refreshContent];
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
    self.locationLabel.text = self.location;
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.machineNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.machineNameLabel.bounds);
    self.locationLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.locationLabel.bounds);
    self.statusLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.statusLabel.bounds);
}

@end
