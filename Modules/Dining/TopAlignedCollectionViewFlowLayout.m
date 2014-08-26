#import "TopAlignedCollectionViewFlowLayout.h"

@interface TopAlignedCollectionViewFlowLayoutRowAttributes : NSObject

@property (nonatomic, assign) float centerY;
@property (nonatomic, assign) float top;

@end

@implementation TopAlignedCollectionViewFlowLayoutRowAttributes
@end

@implementation TopAlignedCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSArray *attributesArray = [super layoutAttributesForElementsInRect:rect];
	
	NSMutableArray *topAlignmentAttributes = [NSMutableArray array];
	
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
	}
	
	return attributesArray;
}

@end