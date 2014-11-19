#import "MITInfiniteScrollCollectionView.h"

@implementation MITInfiniteScrollCollectionView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // By default we want this off, or else it becomes obvious when our content offset resets
        // during infinite scrolling.
        self.showsHorizontalScrollIndicator = NO;
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
    // 1. Our datasource repeats its items 3 times, reporting 3 times as many items as actually exist.
    // 2. Our collection contains only 1 section.
    // 3. Our collection view scrolls horizontally.
    // 4. Our collection view uses a UICollectionViewFlowLayout (or a subclass of it).
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    CGFloat baseWidth = (self.contentSize.width + layout.minimumInteritemSpacing) / 3;
    CGFloat baseOffset = baseWidth;
    
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

- (void)scrollToCenterItemAnimated:(BOOL)animated
{
    NSInteger centerIndex = [self numberOfItemsInSection:0] / 2;
    NSIndexPath *path = [NSIndexPath indexPathForItem:centerIndex inSection:0];
    [self scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
}

@end
