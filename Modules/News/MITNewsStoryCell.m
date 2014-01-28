#import "MITNewsStoryCell.h"
#import "UIImageView+WebCache.h"

@interface MITNewsStoryCell ()

@end

@implementation MITNewsStoryCell
- (void)awakeFromNib
{
    self.contentView.backgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0 alpha:0.5];
    self.titleLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:.25 alpha:0.5];
    self.dekLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:.25 alpha:0.5];
    self.storyImageView.backgroundColor = [UIColor colorWithRed:.25 green:0 blue:0 alpha:0.5];
}

- (void)prepareForReuse
{
    [self.storyImageView cancelCurrentImageLoad];
    self.storyImageView.image = nil;
    self.titleLabel.text = nil;
    self.dekLabel.text = nil;
}
@end
