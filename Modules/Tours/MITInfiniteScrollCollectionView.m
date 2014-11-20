#import "MITInfiniteScrollCollectionView.h"

@implementation MITInfiniteScrollCollectionView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // By default we want this off, or else it becomes obvious when our content offset resets
        // during infinite scrolling.
        self.showsHorizontalScrollIndicator = NO;
        self.contentMultiple = 5;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self recenterIfNecessary];
}

- (void)recenterIfNecessary
{
    // Infinite-scrolling logic here makes the following assumptions:
    // 1. Our datasource repeats its items self.contentMultiple times, reporting more items than actually exist.
    // 2. Our collection contains only 1 section.
    // 3. Our collection view scrolls horizontally.
    // 4. Our collection view uses a UICollectionViewFlowLayout (or a subclass of it).
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    CGFloat baseWidth = (self.contentSize.width + layout.minimumInteritemSpacing) / self.contentMultiple;
    CGFloat baseOffset = baseWidth * (self.contentMultiple - 1) / 2;
    
    CGFloat offset = self.contentOffset.x;
    if (offset > baseOffset + baseWidth) {
        while (offset > baseOffset + baseWidth) {
            offset -= baseWidth;
        }
        self.contentOffset = CGPointMake(offset, self.contentOffset.y);
    } else if (offset < baseOffset) {
        while (offset < baseOffset) {
            offset += baseWidth;
        }
        self.contentOffset = CGPointMake(offset, self.contentOffset.y);
    }
}

@end
