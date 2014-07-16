#import "MITCollectionViewGridLayoutRow.h"
#import "MITNewsConstants.h"

@interface MITCollectionViewGridLayoutRow ()
@property (nonatomic) CGPoint origin;
@end

@implementation MITCollectionViewGridLayoutRow {
    NSMutableArray *_itemLayoutAttributes;
    NSMutableArray *_decorationLayoutAttributes;
    CGFloat _interItemSpacing;
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
        _decorationLayoutAttributes = [[NSMutableArray alloc] init];
        _needsLayout = YES;
    }

    return self;
}

- (void)setNeedsLayout
{
    _bounds.size.height = 0;
    _needsLayout = YES;
}

- (BOOL)needsLayout
{
    return (_needsLayout && ([_itemLayoutAttributes count] > 0));
}

- (void)layoutIfNeeded
{
    if ([self needsLayout]) {
        CGRect bounds = _bounds;
        CGRect layoutBounds = bounds; // Leave an entry point if we want to add edge insets later

        const CGFloat layoutWidth = CGRectGetWidth(layoutBounds);
        const NSUInteger numberOfItems = (self.maximumNumberOfItems > 0 ? self.maximumNumberOfItems : self.numberOfItems);
        const CGFloat interItemSpacing = _interItemSpacing;
        CGFloat itemWidth = (layoutWidth - (interItemSpacing * (numberOfItems - 1))) / numberOfItems;

        __block CGFloat maximumItemHeight = -CGFLOAT_MAX;
        [_itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttributes, NSUInteger idx, BOOL *stop) {
            CGFloat itemOriginY = CGRectGetMinY(layoutBounds);
            CGFloat itemOriginX = CGRectGetMinX(layoutBounds) + (itemWidth * idx) + (interItemSpacing * idx);

            CGRect itemFrame = CGRectMake(itemOriginX, itemOriginY, itemWidth, CGRectGetHeight(itemLayoutAttributes.frame));
            itemLayoutAttributes.frame = itemFrame;

            if (maximumItemHeight < CGRectGetHeight(itemFrame)) {
                maximumItemHeight = CGRectGetHeight(itemFrame);
            }
        }];

        bounds.size.height = maximumItemHeight;
        _bounds = bounds;
        _needsLayout = NO;
    }
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

- (void)setFrame:(CGRect)frame
{
    self.origin = frame.origin;
    self.bounds = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
}

- (CGRect)bounds
{
    [self layoutIfNeeded];
    return _bounds;
}

- (void)setBounds:(CGRect)bounds
{
    CGRect newBounds = bounds;
    newBounds.size.height = 0;

    CGRect oldBounds = _bounds;
    oldBounds.size.height = 0;

    if (!CGRectEqualToRect(newBounds, oldBounds)) {
        bounds.size.height = 0;
        _bounds = bounds;

        [self setNeedsLayout];
    }
}

- (BOOL)isFilled
{
    return (self.maximumNumberOfItems == self.numberOfItems);
}

- (BOOL)addItemForIndexPath:(NSIndexPath*)indexPath withHeight:(CGFloat)itemHeight
{
    if (self.maximumNumberOfItems > 0) {
        if (self.numberOfItems >= self.maximumNumberOfItems) {
            return NO;
        }
    }

    UICollectionViewLayoutAttributes *itemLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemLayoutAttributes.frame = CGRectMake(0, 0, 0, itemHeight);
    [_itemLayoutAttributes addObject:itemLayoutAttributes];

    [self setNeedsLayout];

    return YES;
}

@end
