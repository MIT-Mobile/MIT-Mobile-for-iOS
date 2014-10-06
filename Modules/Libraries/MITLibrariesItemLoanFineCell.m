#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesMITFineItem.h"
#import "MITLibrariesMITLoanItem.h"
#import "UIImageView+WebCache.h"
#import "UIKit+MITAdditions.h"

@interface MITLibrariesItemLoanFineCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *dueDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorAndPublicationDateLabel;

@end

@implementation MITLibrariesItemLoanFineCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dueDateLabel.textColor =
    self.authorAndPublicationDateLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)setContent:(id)content
{
    MITLibrariesMITItem *item = (MITLibrariesMITItem *)content;
    
    self.bookCoverImageView.image = nil;
    if (item.coverImages.count > 0) {
        MITLibrariesCoverImage *coverImage = item.coverImages[0];
        [self.bookCoverImageView sd_setImageWithURL:[NSURL URLWithString:coverImage.url]];
    }
    
    self.itemTitleLabel.text = item.title;

    self.authorAndPublicationDateLabel.text = item.author ? [NSString stringWithFormat:@"%@; %@", item.year, item.author] : item.year;
    
    if ([content isKindOfClass:[MITLibrariesMITFineItem class]]) {
        [self setFineItem:content];
    }
    else if ([content isKindOfClass:[MITLibrariesMITLoanItem class]]) {
        [self setLoanItem:content];
    }
}

- (void)setFineItem:(MITLibrariesMITFineItem *)fineItem
{
    self.dueDateLabel.text = [@"Overdue, " stringByAppendingString:fineItem.formattedAmount];
}

- (void)setLoanItem:(MITLibrariesMITLoanItem *)loanItem
{
    self.dueDateLabel.text = loanItem.dueText;
}

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
}

@end
