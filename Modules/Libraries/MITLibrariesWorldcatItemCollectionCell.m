#import "MITLibrariesWorldcatItemCollectionCell.h"
#import "MITLibrariesWorldcatItem.h"
#import "UIKit+MITLibraries.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MITLibrariesWorldcatItemCollectionCell ()

@property (nonatomic, strong) MITLibrariesWorldcatItem *item;
@property (nonatomic, weak) IBOutlet UILabel *itemTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *yearAndAuthorLabel;
@property (nonatomic, weak) IBOutlet UIImageView *itemImageView;

@end

@implementation MITLibrariesWorldcatItemCollectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.itemTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.yearAndAuthorLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.itemTitleLabel.preferredMaxLayoutWidth = self.itemTitleLabel.bounds.size.width;
    self.yearAndAuthorLabel.preferredMaxLayoutWidth = self.yearAndAuthorLabel.bounds.size.width;
}

- (void)setContent:(MITLibrariesWorldcatItem *)item
{
    if ([_item isEqual:item]) {
        return;
    }
    
    self.item = item;
    
    self.itemImageView.image = nil;
    if (item.coverImages.count > 0) {
        MITLibrariesCoverImage *coverImage = item.coverImages[0];
        [self.itemImageView sd_setImageWithURL:[NSURL URLWithString:coverImage.url]];
    }
    
    self.itemTitleLabel.text = item.title;
    NSString *authorString = [item authorsString];
    self.yearAndAuthorLabel.text = authorString ? [NSString stringWithFormat:@"%@; %@", [item yearsString], [item authorsString]] : [item yearsString];
}

#pragma mark - Sizing

+ (CGFloat)heightForContent:(MITLibrariesWorldcatItem *)item width:(CGFloat)width
{
    MITLibrariesWorldcatItemCollectionCell *sizingCell = [MITLibrariesWorldcatItemCollectionCell sizingCell];
    [sizingCell setContent:item];
    return [MITLibrariesWorldcatItemCollectionCell heightForCell:sizingCell width:width];
}

+ (CGFloat)heightForCell:(MITLibrariesWorldcatItemCollectionCell *)cell width:(CGFloat)width
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

+ (MITLibrariesWorldcatItemCollectionCell *)sizingCell
{
    static MITLibrariesWorldcatItemCollectionCell *sizingCell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCollectionCell class]) bundle:nil];
        sizingCell = [numberedResultCellNib instantiateWithOwner:nil options:nil][0];
    });
    return sizingCell;
}

@end
