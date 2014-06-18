#import "MITCollectionViewGridLayoutRow.h"

@interface MITCollectionViewGridLayoutRow ()
@property (nonatomic) NSUInteger maximumNumberOfItems;
@property (nonatomic) NSUInteger numberOfItems;
@end

@implementation MITCollectionViewGridLayoutRow {
    NSMutableArray *_itemLayoutAttributes;
    NSMutableArray *_decorationLayoutAttributes;
    CGFloat _interItemSpacing;
}

@dynamic itemLayoutAttributes;
@dynamic decorationLayoutAttributes;
@dynamic numberOfItems;

+ (instancetype)rowWithMaximumNumberOfItems:(NSUInteger)maximumNumberOfItems interItemSpacing:(CGFloat)interItemSpacing
{
    MITCollectionViewGridLayoutRow *gridRow = [[self alloc] init];
    gridRow.maximumNumberOfItems = maximumNumberOfItems;
    gridRow->_interItemSpacing = interItemSpacing;
    

    return gridRow;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }

    return self;
}

- (NSUInteger)numberOfItems
{
    return [_itemLayoutAttributes count];
}

- (NSArray*)itemLayoutAttributes
{
    if (!_itemLayoutAttributes) {
        return nil;
    }

    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] initWithArray:_itemLayoutAttributes copyItems:YES];
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        CGRect currentFrame = layoutAttributes.frame;
        currentFrame.origin.x += self.origin.x;
        currentFrame.origin.y += self.origin.y;
        layoutAttributes.frame = currentFrame;
    }];

    return layoutAttributes;
}

- (NSArray*)decorationLayoutAttributes
{
    if (!_decorationLayoutAttributes) {
        return nil;
    }
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] initWithArray:_decorationLayoutAttributes copyItems:YES];
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, self.origin.x, self.origin.y);
    }];
    
    return layoutAttributes;
}

- (CGSize)contentSize
{
    __block CGRect contentFrame = CGRectZero;
    
    NSMutableSet *attributesSet = [[NSMutableSet alloc] init];
    [attributesSet addObjectsFromArray:_itemLayoutAttributes];
    [attributesSet addObjectsFromArray:_decorationLayoutAttributes];

    [attributesSet enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, BOOL *stop) {
        if (CGRectIsEmpty(contentFrame)) {
            contentFrame = layoutAttributes.frame;
        } else {
            contentFrame = CGRectUnion(contentFrame, layoutAttributes.frame);
        }
    }];

    return contentFrame.size;
}

- (CGRect)contentFrame
{
    CGRect contentFrame = CGRectZero;
    contentFrame.size = [self contentSize];
    contentFrame.origin = self.origin;

    return contentFrame;
}

- (BOOL)canAcceptItems
{
    return ([_itemLayoutAttributes count] <= self.numberOfItems);
}

- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath itemSize:(CGSize)size
{
    if (![self canAcceptItems]) {
        return NO;
    }
    
    if (!_itemLayoutAttributes) {
        _itemLayoutAttributes = [[NSMutableArray alloc] init];
    }

    UICollectionViewLayoutAttributes *lastLayoutAttributes = [_itemLayoutAttributes lastObject];
    CGRect layoutFrame = CGRectZero;

    if (lastLayoutAttributes) {
        layoutFrame.origin.x = CGRectGetMaxX(lastLayoutAttributes.frame) + _interItemSpacing;
        layoutFrame.origin.y = CGRectGetMinY(lastLayoutAttributes.frame);
    } else {
        layoutFrame.origin = CGPointZero;
    }

    layoutFrame.size = size;

    UICollectionViewLayoutAttributes *newLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    newLayoutAttributes.frame = layoutFrame;
    [_itemLayoutAttributes addObject:newLayoutAttributes];
    
    [self didInsertItemWithIndexPath:indexPath layoutAttributes:newLayoutAttributes];
    
    return YES;
}

- (void)didInsertItemWithIndexPath:(NSIndexPath*)indexPath layoutAttributes:(UICollectionViewLayoutAttributes*)itemLayoutAttributes
{
    if ([self canAcceptItems]) {
        if (!_decorationLayoutAttributes) {
            _decorationLayoutAttributes = [[NSMutableArray alloc] init];
        }
        
        NSIndexPath *decorationIndexPath = [NSIndexPath indexPathWithIndex:indexPath.item];
        UICollectionViewLayoutAttributes *decorationLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"Divider" withIndexPath:decorationIndexPath];
        
        CGRect decorationFrame = CGRectZero;
        
        decorationFrame.origin.x = CGRectGetMaxX(itemLayoutAttributes.frame) + (floor(_interItemSpacing / 2.0) + 1);
        decorationFrame.origin.y = CGRectGetMinY(itemLayoutAttributes.frame);
        
        CGFloat decorationFrameWidth = 3.0;
        decorationFrame.size = CGSizeMake(decorationFrameWidth, 0);
        decorationLayoutAttributes.frame = decorationFrame;
        
        [_decorationLayoutAttributes addObject:decorationLayoutAttributes];
    } else {
        // This is fine to call here. Since we can't insert any more items
        //  this value shouldn't change so now we can run through the existing
        //  decorations and make sure the heights are set correctly
        CGFloat contentHeight = self.contentSize.height;
        
        [_decorationLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *decorationLayoutAttributes, NSUInteger idx, BOOL *stop) {
            CGRect frame = decorationLayoutAttributes.frame;
            frame.size.height = contentHeight;
            decorationLayoutAttributes.frame = frame;
        }];
        
    }
}

@end
