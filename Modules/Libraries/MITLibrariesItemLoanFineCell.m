#import "MITLibrariesItemLoanFineCell.h"
#import "MITLibrariesMITFineItem.h"
#import "MITLibrariesMITLoanItem.h"
#import "UIImageView+WebCache.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"

@interface MITLibrariesItemLoanFineCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *dueDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorAndPublicationDateLabel;

@end

@implementation MITLibrariesItemLoanFineCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dueDateLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.itemTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.authorAndPublicationDateLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
    
    self.separatorInset = UIEdgeInsetsMake(0, 71, 0, 0);
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
    NSMutableAttributedString *overdueText = [[NSMutableAttributedString alloc] initWithString:fineItem.formattedAmount
                                                                                    attributes:@{NSFontAttributeName : [UIFont librariesDetailStyleFont],
                                                                                                 NSForegroundColorAttributeName : [UIColor mit_closedRedColor]}];
    [overdueText insertAttributedString:self.warningSignString atIndex:0];
    self.dueDateLabel.attributedText = overdueText;
}

- (void)setLoanItem:(MITLibrariesMITLoanItem *)loanItem
{
    NSMutableAttributedString *dueDateText = [[NSMutableAttributedString alloc] initWithString:loanItem.dueText attributes:@{NSFontAttributeName : [UIFont librariesSubtitleStyleFont]}];
    if (loanItem.overdue) {
        [dueDateText addAttribute:NSForegroundColorAttributeName value:[UIColor mit_closedRedColor] range:NSMakeRange(0, dueDateText.length)];
        [dueDateText insertAttributedString:self.warningSignString atIndex:0];
    }
    else {
        [dueDateText addAttribute:NSForegroundColorAttributeName value:[UIColor mit_greyTextColor] range:NSMakeRange(0, dueDateText.length)];
    }
    
    self.dueDateLabel.attributedText = dueDateText;
}

- (NSMutableAttributedString *)warningSignString
{
    static NSMutableAttributedString *warningSignString;
    if (!warningSignString) {
        UIImage *warningSign = [UIImage imageNamed:@"libraries/status-alert"];
        NSTextAttachment *warningSignAttachment = [[NSTextAttachment alloc] init];
        warningSignAttachment.image = warningSign;
        warningSignAttachment.bounds = CGRectMake(0, -2, warningSign.size.width, warningSign.size.height);
        
        warningSignString = [[NSAttributedString attributedStringWithAttachment:warningSignAttachment] mutableCopy];
        [warningSignString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    return warningSignString;
}

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
}

@end
