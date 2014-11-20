#import "MITToursStopCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "UIFont+MITTours.h"
#import "UIKit+MITAdditions.h"

static const CGFloat kBaseWidth = 90;
static const CGFloat kBaseHeight = 190;
static const CGFloat kSelectedPadding = 10;

@interface MITToursStopCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation MITToursStopCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.font = [UIFont toursStopCollectionViewCellTitle];
    
    // If we do not do this, then the contentView will not resize to fit the cell.
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)configureForImageURL:(NSURL *)imageURL title:(NSString *)title selected:(BOOL)selected
{
    [self.imageView sd_setImageWithURL:imageURL];
    self.titleLabel.text = title;
    
    if (selected) {
        self.backgroundColor = [UIColor mit_backgroundColor];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

+ (CGSize)sizeForSelected:(BOOL)selected
{
    if (selected) {
        return CGSizeMake(kBaseWidth + 2 * kSelectedPadding, kBaseHeight);
    }
    return CGSizeMake(kBaseWidth, kBaseHeight);
}

@end
