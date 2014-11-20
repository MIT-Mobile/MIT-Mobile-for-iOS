#import "MITToursStopCollectionViewPagedLayout.h"

@implementation MITToursStopCollectionViewPagedLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pagePosition = CGPointZero;
        self.pageCellScrollPosition = UICollectionViewScrollPositionCenteredHorizontally | UICollectionViewScrollPositionCenteredVertically;
    }
    return self;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    NSArray *attributesArray = [self layoutAttributesForElementsInRect:self.collectionView.bounds];
    if (!attributesArray.count) {
        return proposedContentOffset;
    }

    CGPoint currentOffset = self.collectionView.contentOffset;
    CGFloat shortestSquaredDistance = CGFLOAT_MAX;
    CGPoint bestOffset = proposedContentOffset;
    
    UICollectionViewLayoutAttributes *closestAttributes = nil;
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        if (attributes.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }
        
        CGPoint offset = [self contentOffsetFromAttributes:attributes alignToPoint:self.pagePosition scrollPosition:self.pageCellScrollPosition];
        
        // Reject this element if it would force us to go backwards against velocity
        CGFloat dx = offset.x - currentOffset.x;
        CGFloat dy = offset.y - currentOffset.y;
        CGFloat dot = velocity.x * dx + velocity.y * dy;
        if (dot < 0) {
            continue;
        }
        
        CGFloat squaredDistance = [self squaredDistanceFromPoint:proposedContentOffset toPoint:offset];
        if (squaredDistance < shortestSquaredDistance) {
            closestAttributes = attributes;
            shortestSquaredDistance = squaredDistance;
            bestOffset = offset;
        }
    }
    if (closestAttributes) {
        // Clamp content offset based on content size. This prevents us from choosing a content offset
        // that would cause the collection view to bounce.
        CGFloat maxOffsetX = self.collectionViewContentSize.width - CGRectGetWidth(self.collectionView.bounds) + self.collectionView.contentInset.right;
        CGFloat maxOffsetY = self.collectionViewContentSize.height - CGRectGetHeight(self.collectionView.bounds) + self.collectionView.contentInset.bottom;
        bestOffset.x = MAX(-self.collectionView.contentInset.left, MIN(bestOffset.x, maxOffsetX));
        bestOffset.y = MAX(-self.collectionView.contentInset.top, MIN(bestOffset.y, maxOffsetY));
        
        return bestOffset;
    }
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    return [self targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:CGPointMake(0, 0)];
}

#pragma mark - Helpers

// Compute what the content offset would need to be to align this element to the page position
- (CGPoint)contentOffsetFromAttributes:(UICollectionViewLayoutAttributes *)attributes alignToPoint:(CGPoint)alignToPoint scrollPosition:(UICollectionViewScrollPosition)scrollPosition
{
    CGPoint offset = attributes.center;
    if (scrollPosition & UICollectionViewScrollPositionLeft) {
        offset.x = CGRectGetMinX(attributes.frame);
    } else if (scrollPosition & UICollectionViewScrollPositionRight) {
        offset.x = CGRectGetMaxX(attributes.frame);
    }
    if (scrollPosition & UICollectionViewScrollPositionTop) {
        offset.y = CGRectGetMinY(attributes.frame);
    } else if (scrollPosition & UICollectionViewScrollPositionBottom) {
        offset.y = CGRectGetMaxY(attributes.frame);
    }
    offset.x -= alignToPoint.x;
    offset.y -= alignToPoint.y;
    return offset;
}

- (CGFloat)squaredDistanceFromPoint:(CGPoint)from toPoint:(CGPoint)to
{
    CGFloat dx = from.x - to.x;
    CGFloat dy = from.y - to.y;
    return dx * dx + dy * dy;
}

@end
