#import "TopAlignedStickyHeaderCollectionViewFlowLayout.h"

@interface TopAlignedCollectionViewFlowLayoutRowAttributes : NSObject

@property (nonatomic, assign) float centerY;
@property (nonatomic, assign) float top;

@end

@implementation TopAlignedCollectionViewFlowLayoutRowAttributes
@end


@interface TopAlignedStickyHeaderCollectionViewFlowLayout ()

@property (nonatomic, assign) CGFloat previousCollectionViewContentOffsetY;

@end

@implementation TopAlignedStickyHeaderCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSMutableArray *attributesArray = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
	
	NSMutableArray *topAlignmentAttributes = [NSMutableArray array];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *maxYCellsBySection = [[NSMutableDictionary alloc] init];
	
	for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
		BOOL found = NO;
		for (TopAlignedCollectionViewFlowLayoutRowAttributes *info in topAlignmentAttributes) {
			if (fabs(info.centerY - attributes.center.y) < 1) {
				if (info.top > attributes.frame.origin.y) {
					info.centerY = attributes.center.y;
					info.top = attributes.frame.origin.y;
				}
                found = YES;
				break;
			}
		}
        
		if (!found) {
			TopAlignedCollectionViewFlowLayoutRowAttributes *rowInfo = [TopAlignedCollectionViewFlowLayoutRowAttributes new];
			rowInfo.centerY = attributes.center.y;
			rowInfo.top = attributes.frame.origin.y;
			[topAlignmentAttributes addObject:rowInfo];
		}
	}
	
	for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
		for (TopAlignedCollectionViewFlowLayoutRowAttributes *info in topAlignmentAttributes) {
			if (fabs(info.centerY - attributes.center.y) < 1) {
				CGRect attributesFrame = attributes.frame;
				attributesFrame.origin.y = info.top;
				attributes.frame = attributesFrame;
			}
		}
        
        NSIndexPath *indexPath = [attributes indexPath];
        if ([[attributes representedElementKind] isEqualToString:UICollectionElementKindSectionHeader]) {
            [headers setObject:attributes forKey:@(indexPath.section)];
        } else if ([[attributes representedElementKind] isEqualToString:UICollectionElementKindSectionFooter]) {
            // Not implemented
        } else {
            NSIndexPath *indexPath = [attributes indexPath];
            
            UICollectionViewLayoutAttributes *currentMaxYAttribute = [maxYCellsBySection objectForKey:@(indexPath.section)];
            
            // Get the bottom most cell of that section
            if (!currentMaxYAttribute || CGRectGetMaxY(attributes.frame) > CGRectGetMaxY(currentMaxYAttribute.frame)) {
                [maxYCellsBySection setObject:attributes forKey:@(indexPath.section)];
            }
        }
        
        attributes.zIndex = 1;
	}
    
    [maxYCellsBySection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSIndexPath *indexPath = [obj indexPath];
        NSNumber *sectionKey = @(indexPath.section);
        
        UICollectionViewLayoutAttributes *headerAttributes = headers[sectionKey];
        // CollectionView automatically removes headers not in bounds
        if (!headerAttributes) {
            headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                          atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
            
            if (headerAttributes) {
                [attributesArray addObject:headerAttributes];
                [headers setObject:headerAttributes forKey:sectionKey];
            }
        }
        
        [self updateHeaderAttributes:headerAttributes lastCellAttributes:maxYCellsBySection[sectionKey]];
    }];
    
    self.previousCollectionViewContentOffsetY = self.collectionView.contentOffset.y;
	
	return attributesArray;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

#pragma mark - Helpers

- (void)updateHeaderAttributes:(UICollectionViewLayoutAttributes *)attributes lastCellAttributes:(UICollectionViewLayoutAttributes *)lastCellAttributes
{
    CGRect currentBounds = self.collectionView.bounds;
    attributes.zIndex = 1024;
    attributes.hidden = NO;
    
    CGPoint origin = attributes.frame.origin;
    
    CGFloat sectionMaxY = CGRectGetMaxY(lastCellAttributes.frame) - attributes.frame.size.height;
    CGFloat topLockY = currentBounds.origin.y;

    CGFloat maxY = MIN(MAX(topLockY, attributes.frame.origin.y), sectionMaxY);
    
    origin.y = maxY;
    
    attributes.frame = CGRectMake(origin.x, origin.y, attributes.frame.size.width, attributes.frame.size.height);
}

@end