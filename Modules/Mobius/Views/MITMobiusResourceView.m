#import "MITMobiusResourceView.h"
#import "MITAdditions.h"
#import "MITResourceConstants.h"

@interface MITMobiusResourceView ()

@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *machineStatus;

@end

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

- (void)setStatus:(MITMobiusResourceStatus)status withText:(NSString *)statusText
{
    switch (status) {
        case MITMobiusResourceStatusOffline: {
            self.machineStatus.image = [UIImage imageNamed:MITImageLibrariesStatusAlert];
        } break;
            
        case MITMobiusResourceStatusOnline: {
            self.machineStatus = nil;
        } break;
            
        case MITMobiusResourceStatusUnknown: {
            self.machineStatus = nil;
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
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.machineNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.machineNameLabel.bounds);
}

@end
