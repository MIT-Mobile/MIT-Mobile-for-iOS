#import "MITCollectionViewGridLayoutRow.h"
#import "MITNewsConstants.h"

@interface MITCollectionViewGridLayoutRow ()
@property (nonatomic) BOOL needsLayout;
@end

@implementation MITCollectionViewGridLayoutRow {
    NSMutableArray *_itemLayoutAttributes;
    BOOL _needsLayout;
}

@synthesize bounds = _bounds;
@dynamic frame;
@dynamic itemLayoutAttributes;
@dynamic numberOfItems;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _itemLayoutAttributes = [[NSMutableArray alloc] init];
        _needsLayout = YES;
    }

    return self;
}

- (void)setNeedsLayout
{
    _needsLayout = YES;
}

- (void)layoutIfNeeded
{
    if ([self needsLayout]) {
        const CGFloat itemWidth = self.columnWidth;
        const CGFloat interItemSpacing = self.interItemPadding;
        
        __block CGPoint origin = CGPointMake(0, 0);
        [_itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttributes, NSUInteger idx, BOOL *stop) {
            CGRect itemFrame = itemLayoutAttributes.frame;
            itemFrame.origin = origin;
            itemFrame.size.width = itemWidth;
            itemLayoutAttributes.frame = itemFrame;
            
            origin.x += itemWidth;
            origin.x += interItemSpacing;
        }];
        
        _bounds = [self _bounds];
        _needsLayout = NO;
    }
}

- (NSUInteger)numberOfItems
{
    return [_itemLayoutAttributes count];
}

- (NSArray*)itemLayoutAttributes
{
    [self layoutIfNeeded];
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] initWithArray:_itemLayoutAttributes copyItems:YES];
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, self.origin.x, self.origin.y);
    }];

    return layoutAttributes;
}

- (CGRect)frame
{
    CGRect frame = self.bounds;
    frame = CGRectOffset(frame, self.origin.x, self.origin.y);
    return frame;
}

- (CGRect)_bounds
{
    __block CGRect contentFrame = CGRectZero;
    [_itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttributes, NSUInteger idx, BOOL *stop) {
        contentFrame = CGRectUnion(contentFrame, itemLayoutAttributes.frame);
    }];
    
    contentFrame.origin = CGPointZero;
    
    return contentFrame;
}

- (CGRect)bounds
{
    [self layoutIfNeeded];
    return _bounds;
}

- (void)setColumnWidth:(CGFloat)columnWidth
{
    _columnWidth = columnWidth;
    [self setNeedsLayout];
}

- (void)setInterItemPadding:(CGFloat)interItemPadding
{
    _interItemPadding = interItemPadding;
    [self setNeedsLayout];
}


- (BOOL)isFilled
{
    return (!self.maximumNumberOfItems || (self.maximumNumberOfItems == self.numberOfItems));
}

- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath withHeight:(CGFloat)itemHeight
{
    if (self.isFilled) {
        return NO;
    }

    UICollectionViewLayoutAttributes *itemLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemLayoutAttributes.frame = CGRectMake(0, 0, 0, itemHeight);
    [_itemLayoutAttributes addObject:itemLayoutAttributes];

    [self setNeedsLayout];

    return YES;
}

@end
