#import <Foundation/Foundation.h>

#import "MITCollectionViewGridLayoutRow.h"
#import "MITNewsConstants.h"

@interface MITCollectionViewGridLayoutRow ()
@property (nonatomic,strong) NSMutableDictionary *mutableItemLayoutAttributes;
@property (nonatomic) BOOL needsLayout;
@end

@implementation MITCollectionViewGridLayoutRow
@synthesize bounds = _bounds;

@dynamic frame;
@dynamic itemLayoutAttributes;
@dynamic numberOfItems;

- (instancetype)init
{
    self = [super init];
    if (self) {
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
        
        __block CGPoint origin = CGPointMake(0,0);
        [[self _itemLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttributes, NSUInteger idx, BOOL *stop) {
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
    return [self.mutableItemLayoutAttributes count];
}

- (NSArray*)_itemLayoutAttributes
{
    return [[self.mutableItemLayoutAttributes allValues] sortedArrayUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes* obj1, UICollectionViewLayoutAttributes* obj2) {
        return [obj1.indexPath compare:obj2.indexPath];
    }];
}

- (NSArray*)itemLayoutAttributes
{
    [self layoutIfNeeded];
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] initWithArray:[self _itemLayoutAttributes] copyItems:YES];
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, self.origin.x, self.origin.y);
    }];
    
    return layoutAttributes;
}

- (NSMutableDictionary*)mutableItemLayoutAttributes
{
    if (!_mutableItemLayoutAttributes) {
        _mutableItemLayoutAttributes = [[NSMutableDictionary alloc] init];
    }
    
    return _mutableItemLayoutAttributes;
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
    
    // No need to worry about ordering here since union is commutative
    [[self.mutableItemLayoutAttributes allValues] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttributes, NSUInteger idx, BOOL *stop) {
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

- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath
{
    if (self.isFilled) {
        return NO;
    }
    
    UICollectionViewLayoutAttributes *itemLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemLayoutAttributes.frame = CGRectMake(0, 0, 0, 0);
    self.mutableItemLayoutAttributes[indexPath] = itemLayoutAttributes;
    
    [self setNeedsLayout];
    
    return YES;
}

- (void)setHeight:(CGFloat)height forItemWithIndexPath:(NSIndexPath*)indexPath
{
    if (!self.mutableItemLayoutAttributes[indexPath]) {
        [self addItemForIndexPath:indexPath];
    }
    
    UICollectionViewLayoutAttributes *layoutAttributes = self.mutableItemLayoutAttributes[indexPath];
    CGRect frame = layoutAttributes.frame;
    frame.size.height = height;
    layoutAttributes.frame = frame;
    
    // No need to force a re-layout after this action since, if an item was added, it should be set to true and if not,
    // we are only tweaking the height (and the bounds is calculated dynamically)
}

@end
