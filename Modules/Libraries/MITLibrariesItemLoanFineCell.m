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

@property (strong, nonatomic) NSMutableAttributedString *warningSignString;

@end

@implementation MITLibrariesItemLoanFineCell

- (void)awakeFromNib
{
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
    NSMutableAttributedString *overdueText = [[NSMutableAttributedString alloc] initWithString:[@"Overdue, " stringByAppendingString:fineItem.formattedAmount]
                                                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0],
                                                                                                 NSForegroundColorAttributeName : [UIColor mit_closedRedColor]}];
    [overdueText insertAttributedString:self.warningSignString atIndex:0];
    self.dueDateLabel.attributedText = overdueText;
}

- (void)setLoanItem:(MITLibrariesMITLoanItem *)loanItem
{
    NSMutableAttributedString *dueDateText = [[NSMutableAttributedString alloc] initWithString:loanItem.dueText attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]}];
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
    if (!_warningSignString) {
        UIImage *warningSign = [UIImage imageNamed:@"libraries/status-alert"];
        NSTextAttachment *warningSignAttachment = [[NSTextAttachment alloc] init];
        warningSignAttachment.image = warningSign;
        warningSignAttachment.bounds = CGRectMake(0, -2, warningSign.size.width, warningSign.size.height);
        
        _warningSignString = [[NSAttributedString attributedStringWithAttachment:warningSignAttachment] mutableCopy];
        [_warningSignString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    return _warningSignString;
}

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
}

@end
