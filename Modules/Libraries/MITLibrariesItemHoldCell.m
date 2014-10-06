#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesMITHoldItem.h"
#import "UIImageView+WebCache.h"
#import "UIKit+MITAdditions.h"

@interface MITLibrariesItemHoldCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *readyForPickupLabel;
@property (weak, nonatomic) IBOutlet UILabel *holdDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorAndPublicationDateLabel;

@end

@implementation MITLibrariesItemHoldCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.holdDateLabel.textColor =
    self.authorAndPublicationDateLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)setContent:(id)content
{
    MITLibrariesMITHoldItem *item = (MITLibrariesMITHoldItem *)content;
    
    self.bookCoverImageView.image = nil;
    if (item.coverImages.count > 0) {
        MITLibrariesCoverImage *coverImage = item.coverImages[0];
        [self.bookCoverImageView sd_setImageWithURL:[NSURL URLWithString:coverImage.url]];
    }
    
    self.itemTitleLabel.text = item.title;
    
    self.holdDateLabel.text = item.status;
    
    if ([[item.status lowercaseString] isEqualToString:@"in process"]) {
        self.readyForPickupLabel.text = nil;
    }
    else {
        self.readyForPickupLabel.text = item.pickupLocation;
    }
    
    self.authorAndPublicationDateLabel.text = item.author ? [NSString stringWithFormat:@"%@; %@", item.year, item.author] : item.year;
}

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
}

@end
