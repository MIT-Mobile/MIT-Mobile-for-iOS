#import "MITMartyResourceTableViewCell.h"
#import "MITMartyModel.h"

@interface MITMartyResourceTableViewCell ()
@property(nonatomic,weak) IBOutlet UILabel *machineNameLabel;
@property(nonatomic,weak) IBOutlet UILabel *locationLabel;
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;
@end

@implementation MITMartyResourceTableViewCell

- (void)awakeFromNib {
    self.index = NSNotFound;
}

- (void)prepareForReuse
{
    _index = NSNotFound;
    _machineName = nil;
    _location = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setIndex:(NSUInteger)index
{
    if (_index != index) {
        _index = index;
        [self _updateMachineName];
    }
}

- (void)setMachineName:(NSString *)machineName
{
    if (![_machineName isEqualToString:machineName]) {
        _machineName = [machineName copy];
        [self _updateMachineName];
    }
}

- (void)setLocation:(NSString *)location
{
    if (![_location isEqualToString:location]) {
        _location = [location copy];
        self.locationLabel.text = _location;
        [self.contentView setNeedsLayout];
    }
}

- (void)setStatus:(MITMartyResourceStatus)status withText:(NSString *)statusText
{
    self.statusLabel.text = [statusText copy];
    
    switch (status) {
        case MITMartyResourceStatusOffline: {
            self.statusLabel.textColor = [UIColor redColor];
        } break;
            
        case MITMartyResourceStatusOnline: {
            self.statusLabel.textColor = [UIColor greenColor];
        } break;
            
        case MITMartyResourceStatusUnknown: {
            self.statusLabel.textColor = [UIColor orangeColor];
        } break;
    }
    
    [self.statusLabel sizeToFit];
}


- (void)_updateMachineName
{
    NSString *machineName = nil;
    if (self.index == NSNotFound) {
        machineName = self.machineName;
    } else {
        machineName = [NSString stringWithFormat:@"%lu. %@",(unsigned long)self.index,self.machineName];
    }
    
    self.machineNameLabel.text = machineName;
}

@end
