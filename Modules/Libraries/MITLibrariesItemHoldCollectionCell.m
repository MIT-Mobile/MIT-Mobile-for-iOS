#import "MITLibrariesItemHoldCollectionCell.h"
#import "MITLibrariesMITHoldItem.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIKit+MITAdditions.h"

@interface MITLibrariesItemHoldCollectionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *readyForPickupLabel;
@property (weak, nonatomic) IBOutlet UILabel *holdDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorAndPublicationDateLabel;

@end

@implementation MITLibrariesItemHoldCollectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.holdDateLabel.textColor =
    self.authorAndPublicationDateLabel.textColor = [UIColor mit_greyTextColor];
    self.readyForPickupLabel.text = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.readyForPickupLabel.preferredMaxLayoutWidth = self.readyForPickupLabel.bounds.size.width;
    self.holdDateLabel.preferredMaxLayoutWidth = self.holdDateLabel.bounds.size.width;
    self.itemTitleLabel.preferredMaxLayoutWidth = self.itemTitleLabel.bounds.size.width;
    self.authorAndPublicationDateLabel.preferredMaxLayoutWidth = self.authorAndPublicationDateLabel.bounds.size.width;
}

- (void)setContent:(MITLibrariesMITHoldItem *)item
{
    self.bookCoverImageView.image = nil;
    if (item.coverImages.count > 0) {
        MITLibrariesCoverImage *coverImage = item.coverImages[0];
        [self.bookCoverImageView sd_setImageWithURL:[NSURL URLWithString:coverImage.url]];
    }
    
    self.itemTitleLabel.text = item.title;
    
    self.holdDateLabel.text = item.status;
    
    if (item.readyForPickup) {
        NSMutableAttributedString *readyString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Ready at %@", item.pickupLocation] attributes:@{NSForegroundColorAttributeName : [UIColor mit_openGreenColor]}];
        [readyString insertAttributedString:[self readyIconString] atIndex:0];
        self.readyForPickupLabel.attributedText = readyString;
    }
    else {
        self.readyForPickupLabel.attributedText = nil;
    }
    
    self.authorAndPublicationDateLabel.text = item.author ? [NSString stringWithFormat:@"%@; %@", item.year, item.author] : item.year;
}

- (NSMutableAttributedString *)readyIconString
{
    static NSMutableAttributedString *readyIconString;
    if (!readyIconString) {
        UIImage *readyIcon = [UIImage imageNamed:MITImageLibrariesStatusReady];
        NSTextAttachment *readyIconAttachment = [[NSTextAttachment alloc] init];
        readyIconAttachment.image = readyIcon;
        readyIconAttachment.bounds = CGRectMake(0, -2, readyIcon.size.width, readyIcon.size.height);
        
        readyIconString = [[NSAttributedString attributedStringWithAttachment:readyIconAttachment] mutableCopy];
        [readyIconString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    return readyIconString;
}

#pragma mark - Sizing

+ (CGFloat)heightForContent:(MITLibrariesMITHoldItem *)item width:(CGFloat)width
{
    MITLibrariesItemHoldCollectionCell *sizingCell = [MITLibrariesItemHoldCollectionCell sizingCell];
    [sizingCell setContent:item];
    return [MITLibrariesItemHoldCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITLibrariesItemHoldCollectionCell *)cell width:(CGFloat)width
{
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    CGRect frame = cell.frame;
    frame.size.width = floor(width);
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = ceil([cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    return MAX(44, height);
}

+ (MITLibrariesItemHoldCollectionCell *)sizingCell
{
    static MITLibrariesItemHoldCollectionCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemHoldCollectionCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
