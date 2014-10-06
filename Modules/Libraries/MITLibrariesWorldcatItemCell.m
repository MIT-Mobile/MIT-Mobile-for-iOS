#import "MITLibrariesWorldcatItemCell.h"
#import "MITLibrariesWorldcatItem.h"
#import "UIKit+MITLibraries.h"
#import "UIImageView+WebCache.h"

@interface MITLibrariesWorldcatItemCell ()

@property (nonatomic, strong) MITLibrariesWorldcatItem *item;
@property (nonatomic, assign) UIEdgeInsets separatorInsetsBeforeHiding;

@end

@implementation MITLibrariesWorldcatItemCell

- (void)awakeFromNib
{
    _showsSeparator = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.itemTitleLabel setLibrariesTextStyle:MITLibrariesTextStyleBookTitle];
    [self.yearAndAuthorLabel setLibrariesTextStyle:MITLibrariesTextStyleSubtitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.showsSeparator) {
        self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
    }
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

- (void)setShowsSeparator:(BOOL)showsSeparator
{
    if (_showsSeparator == showsSeparator) {
        return;
    }
    
    _showsSeparator = showsSeparator;
    
    if (_showsSeparator) {
        self.separatorInset = self.separatorInsetsBeforeHiding;
    } else {
        self.separatorInsetsBeforeHiding = self.separatorInset;
        self.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
    }
}

#pragma mark - Cell Sizing

+ (CGFloat)estimatedCellHeight
{
    return 105.0;
}

@end
