#import "MITToursInfoCell.h"

@interface MITToursInfoCell ()

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

@implementation MITToursInfoCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width, 0, 0);
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
