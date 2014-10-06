#import "MITLibrariesHoursCell.h"
#import "MITLibrariesTerm.h"
#import "UIKit+MITAdditions.h"

@interface MITLibrariesHoursCell ()

@property (weak, nonatomic) IBOutlet UILabel *termNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *termHoursLabel;

@end

@implementation MITLibrariesHoursCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.termNameLabel.textColor = [UIColor mit_tintColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width + 1, 0, 0);
}

- (void)setContent:(MITLibrariesTerm *)term
{
    self.termNameLabel.text = [term termDescription];
    self.termHoursLabel.text = [term termHoursDescription];
    
    [self layoutIfNeeded];
}

+ (CGFloat)estimatedCellHeight
{
    return 67.0;
}

@end
