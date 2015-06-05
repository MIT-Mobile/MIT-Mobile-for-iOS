#import "MITMobiusResourceView.h"
#import "MITAdditions.h"
#import "MITResourceConstants.h"

@interface MITMobiusResourceView ()

@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property(nonatomic,weak) IBOutlet UILabel *modelLabel;
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

- (void)setModel:(NSString *)model
{
    if (![_model isEqualToString:model]) {
        _model = [model copy];
        [self _refreshContent];
    }
}

- (void)setStatus:(MITMobiusResourceStatus)status
{
    switch (status) {
        case MITMobiusResourceStatusOffline: {
            self.machineStatus.image = [UIImage imageNamed:MITImageMobiusResourceOffline];
            self.machineNameLabel.enabled = NO;
        } break;
            
        case MITMobiusResourceStatusOnline: {
            self.machineStatus.image = nil;
            self.machineNameLabel.enabled = YES;
        } break;
            
        case MITMobiusResourceStatusUnknown: {
            self.machineStatus.image = nil;
            self.machineNameLabel.enabled = NO;
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
    self.modelLabel.text = self.model;
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.machineNameLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.machineNameLabel.bounds);
}

@end
