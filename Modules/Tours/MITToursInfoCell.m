#import "MITToursInfoCell.h"

@interface MITToursInfoCell ()

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;

@end

@implementation MITToursInfoCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.separatorHeight.constant = 0.5;
}

- (void)setContent:(id)content
{
    self.infoLabel.text = (NSString *)content;
}

+ (CGFloat)estimatedCellHeight
{
    return 67.0;
}

@end
