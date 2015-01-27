#import "MITLibrariesItemHoldCell.h"
#import "MITLibrariesMITHoldItem.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"

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
    self.readyForPickupLabel.text = nil;
    
    [self.itemTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.holdDateLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    [self.authorAndPublicationDateLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    
    self.ipadSeparator.backgroundColor = [UIColor mit_cellSeparatorColor];
    self.separatorInset = UIEdgeInsetsMake(0, 71, 0, 0);
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

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
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

@end
