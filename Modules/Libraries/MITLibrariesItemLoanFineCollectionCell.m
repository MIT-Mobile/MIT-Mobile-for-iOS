#import "MITLibrariesItemLoanFineCollectionCell.h"
#import "MITLibrariesMITLoanItem.h"
#import "MITLibrariesMITFineItem.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIKit+MITAdditions.h"
#import "MITResourceConstants.h"

@interface MITLibrariesItemLoanFineCollectionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *dueDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorAndPublicationDateLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dueDateLabelTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *itemTitleLabelTrailingConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *authorAndPublicationDateLabelTrailingConstraint;

@end

@implementation MITLibrariesItemLoanFineCollectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.dueDateLabel.textColor =
    self.authorAndPublicationDateLabel.textColor = [UIColor mit_greyTextColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.itemTitleLabel.preferredMaxLayoutWidth = self.contentView.bounds.size.width - self.itemTitleLabel.frame.origin.x - self.itemTitleLabelTrailingConstraint.constant;
    self.dueDateLabel.preferredMaxLayoutWidth = self.contentView.bounds.size.width - self.dueDateLabel.frame.origin.x - self.dueDateLabelTrailingConstraint.constant;
    self.authorAndPublicationDateLabel.preferredMaxLayoutWidth = self.contentView.bounds.size.width - self.authorAndPublicationDateLabel.frame.origin.x - self.authorAndPublicationDateLabelTrailingConstraint.constant;
}

- (void)setContent:(MITLibrariesMITItem *)item
{
    self.bookCoverImageView.image = nil;
    if (item.coverImages.count > 0) {
        MITLibrariesCoverImage *coverImage = item.coverImages[0];
        [self.bookCoverImageView sd_setImageWithURL:[NSURL URLWithString:coverImage.url]];
    }
    
    self.itemTitleLabel.text = item.title;
    
    self.authorAndPublicationDateLabel.text = item.author ? [NSString stringWithFormat:@"%@; %@", item.year, item.author] : item.year;
    
    if ([item isKindOfClass:[MITLibrariesMITFineItem class]]) {
        [self setFineItem:(MITLibrariesMITFineItem *)item];
    }
    else if ([item isKindOfClass:[MITLibrariesMITLoanItem class]]) {
        [self setLoanItem:(MITLibrariesMITLoanItem *)item];
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
    static NSMutableAttributedString *warningSignString;
    if (!warningSignString) {
        UIImage *warningSign = [UIImage imageNamed:MITImageLibrariesStatusAlert];
        NSTextAttachment *warningSignAttachment = [[NSTextAttachment alloc] init];
        warningSignAttachment.image = warningSign;
        warningSignAttachment.bounds = CGRectMake(0, -2, warningSign.size.width, warningSign.size.height);
        
        warningSignString = [[NSAttributedString attributedStringWithAttachment:warningSignAttachment] mutableCopy];
        [warningSignString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    return warningSignString;
}

#pragma mark - Sizing

+ (CGFloat)heightForContent:(MITLibrariesMITItem *)item width:(CGFloat)width
{
    MITLibrariesItemLoanFineCollectionCell *sizingCell = [MITLibrariesItemLoanFineCollectionCell sizingCell];
    [sizingCell setContent:item];
    return [MITLibrariesItemLoanFineCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITLibrariesItemLoanFineCollectionCell *)cell width:(CGFloat)width
{
    CGRect frame = cell.frame;
    frame.size.width = floorf(width);
    cell.frame = frame;
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    CGFloat height = ceilf([cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
    return MAX(44, height);
}

+ (MITLibrariesItemLoanFineCollectionCell *)sizingCell
{
    static MITLibrariesItemLoanFineCollectionCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesItemLoanFineCollectionCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
