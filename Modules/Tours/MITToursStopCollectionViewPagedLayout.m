#import "MITToursStopCollectionViewPagedLayout.h"

@implementation MITToursStopCollectionViewPagedLayout

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    NSArray *attributesArray = [self layoutAttributesForElementsInRect:self.collectionView.bounds];
    if (!attributesArray.count) {
        return proposedContentOffset;
    }

    CGFloat halfWidth = self.collectionView.bounds.size.width * 0.5;
    CGFloat halfHeight = self.collectionView.bounds.size.height * 0.5;
    CGPoint proposedCenter = CGPointMake(proposedContentOffset.x + halfWidth,
                                         proposedContentOffset.y + halfHeight);
    CGPoint currentCenter = CGPointMake(self.collectionView.contentOffset.x + halfWidth,
                                        self.collectionView.contentOffset.y + halfHeight);
    
    CGFloat shortestSquaredDistance = CGFLOAT_MAX;
    
    UICollectionViewLayoutAttributes *closestAttributes = nil;
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        if (attributes.representedElementCategory != UICollectionElementCategoryCell) {
            continue;
        }
        
        // Reject this element if it would force us to go backwards against velocity
        CGFloat dx = attributes.center.x - currentCenter.x;
        CGFloat dy = attributes.center.y - currentCenter.y;
        CGFloat dot = velocity.x * dx + velocity.y * dy;
        if (dot < 0) {
            continue;
        }
        
        CGFloat squaredDistance = [self squaredDistanceFromPoint:proposedCenter toPoint:attributes.center];
        if (squaredDistance < shortestSquaredDistance) {
            closestAttributes = attributes;
            shortestSquaredDistance = squaredDistance;
        }
    }
    if (closestAttributes) {
        return CGPointMake(closestAttributes.center.x - halfWidth,
                           closestAttributes.center.y - halfHeight);
    }
    return proposedContentOffset;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    return [self targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:CGPointMake(0, 0)];
}

#pragma mark - Helpers

- (CGFloat)squaredDistanceFromPoint:(CGPoint)from toPoint:(CGPoint)to
{
    CGFloat dx = from.x - to.x;
    CGFloat dy = from.y - to.y;
    return dx * dx + dy * dy;
}

@end
