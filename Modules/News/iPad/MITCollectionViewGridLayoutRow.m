#import "MITCollectionViewGridLayoutRow.h"

@interface MITCollectionViewGridLayoutRow ()
@property (nonatomic,readonly) CGFloat interItemSpacing;
@end

@implementation MITCollectionViewGridLayoutRow {
    NSMutableArray *_itemLayoutAttributes;
    NSMutableArray *_decorationLayoutAttributes;
}

@dynamic itemLayoutAttributes;
@dynamic decorationLayoutAttributes;
@synthesize interItemSpacing = _interItemSpacing;

+ (instancetype)rowWithNumberOfItems:(NSUInteger)numberOfItems interItemSpacing:(CGFloat)interItemSpacing
{
    MITCollectionViewGridLayoutRow *gridRow = [[self alloc] init];
    gridRow.numberOfItems = numberOfItems;
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
    return ([_layoutAttributes count] <= self.numberOfItems);
}

- (NSIndexPath*)layoutAttributesForIndexPath:(NSIndexPath*)indexPath
{
    __block UICollectionViewLayoutAttributes *resultLayoutAttributes = nil;
    [_layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes* layoutAttributes, NSUInteger idx, BOOL *stop) {
        if ([layoutAttributes.indexPath isEqual:indexPath]) {
            resultLayoutAttributes = layoutAttributes;
            (*stop) = YES;
        }
    }];

    return [resultLayoutAttributes copy];
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
        layoutFrame.origin.x = CGRectGetMaxX(lastLayoutAttributes.frame) + self.interItemSpacing;
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

- (void)didInsertItemWithIndexPath:(NSIndexPath*)indexPath layoutAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes
{
    if ([self canAcceptItems]) {
        if (!_decorationLayoutAttributes) {
            _decorationLayoutAttributes = [[NSMutableArray alloc] init];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:indexPath.item];
        UICollectionViewLayoutAttributes *layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"Divider" withIndexPath:indexPath];
        
        CGRect decorationFrame = CGRectZero;
        
        CGFloat decorationSpacing = floor(
        
    }
}

@end
