#import "MITToursStopCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "UIFont+MITTours.h"

@interface MITToursStopCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation MITToursStopCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.font = [UIFont toursButtonSubtitle];
}

- (void)configureForImageURL:(NSURL *)imageURL title:(NSString *)title
{
    [self.imageView sd_setImageWithURL:imageURL];
    self.titleLabel.text = title;
}

@end
