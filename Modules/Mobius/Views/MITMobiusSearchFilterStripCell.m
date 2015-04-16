#import "MITMobiusSearchFilterStripCell.h"

@interface MITMobiusSearchFilterStripCell ()

@property (nonatomic, weak) IBOutlet UILabel *filterLabel;

@end

@implementation MITMobiusSearchFilterStripCell

- (void)awakeFromNib
{
    // Initialization code
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
