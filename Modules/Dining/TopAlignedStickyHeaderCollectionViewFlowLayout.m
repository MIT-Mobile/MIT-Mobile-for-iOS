#import "TopAlignedStickyHeaderCollectionViewFlowLayout.h"

@interface TopAlignedCollectionViewFlowLayoutRowAttributes : NSObject

@property (nonatomic, assign) float centerY;
@property (nonatomic, assign) float top;

@end

@implementation TopAlignedCollectionViewFlowLayoutRowAttributes
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
            // Not implemeneted
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
        NSNumber *indexPathKey = @(indexPath.section);
        
        UICollectionViewLayoutAttributes *header = headers[indexPathKey];
        // CollectionView automatically removes headers not in bounds
        if (!header) {
            header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                          atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
            
            if (header) {
                [attributesArray addObject:header];
            }
        }
        
        [self updateHeaderAttributes:header lastCellAttributes:maxYCellsBySection[indexPathKey]];
    }];
	
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
    CGFloat y = CGRectGetMaxY(currentBounds) - currentBounds.size.height + self.collectionView.contentInset.top;

    CGFloat maxY = MIN(MAX(y, attributes.frame.origin.y), sectionMaxY);
    
    origin.y = maxY;
    
    attributes.frame = (CGRect){
        origin,
        attributes.frame.size
    };
}

@end