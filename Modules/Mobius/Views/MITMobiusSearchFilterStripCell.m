#import "MITMobiusSearchFilterStripCell.h"

@interface MITMobiusSearchFilterStripCell ()

@property (nonatomic, weak) IBOutlet UILabel *filterLabel;

@end

@implementation MITMobiusSearchFilterStripCell

- (void)awakeFromNib
{
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.6];
    backgroundView.layer.cornerRadius = 2;
    self.selectedBackgroundView = backgroundView;
}

- (void)setText:(NSString *)text
{
    self.filterLabel.text = text;
}

+ (MITMobiusSearchFilterStripCell *)sizingCell
{
    static MITMobiusSearchFilterStripCell *sizingCell;
    
    if (!sizingCell) {
        UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
        sizingCell = [cellNib instantiateWithOwner:nil options:nil][0];
    }
    
    return sizingCell;
}

@end
