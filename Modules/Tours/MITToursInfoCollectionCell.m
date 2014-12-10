#import "MITToursInfoCollectionCell.h"

@implementation MITToursInfoCollectionCell

+ (CGSize)sizeForInfoText:(NSString *)infoText buttonText:(NSString *)buttonText
{
    MITToursInfoCollectionCell *sizingCell = [self sizingCell];
    [sizingCell configureForInfoText:infoText buttonText:buttonText];
    return [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

+ (MITToursInfoCollectionCell *)sizingCell
{
    static MITToursInfoCollectionCell *sizingCell;
    if (sizingCell == nil) {
        UINib *nib = [UINib nibWithNibName:@"MITToursInfoCollectionCell" bundle:nil];
        sizingCell = [nib instantiateWithOwner:nil options:nil][0];
    }
    return sizingCell;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.infoTextLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds);
    self.infoButton.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bounds);
    
    // If we do not do this, then the contentView will not resize to fit the cell.
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)configureForInfoText:(NSString *)infoText buttonText:(NSString *)buttonText
{
    self.infoTextLabel.text = infoText;
    [self.infoButton setTitle:buttonText forState:UIControlStateNormal];
}

@end
