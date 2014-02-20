#import "MITNewsStoryCell.h"
#import "UIImageView+WebCache.h"

@interface MITNewsStoryCell ()

@end

@implementation MITNewsStoryCell
- (void)prepareForReuse
{
    [self.storyImageView cancelCurrentImageLoad];
    self.storyImageView.image = nil;
    self.titleLabel.text = nil;
    self.dekLabel.text = nil;
}
@end
