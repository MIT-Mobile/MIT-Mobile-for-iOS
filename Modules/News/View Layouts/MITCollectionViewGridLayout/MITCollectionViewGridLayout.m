#import "MITCollectionViewGridLayout.h"
#import "MITCollectionViewGridLayoutSection.h"
#import "MITNewsConstants.h"
#import "MITCollectionViewGridDividerView.h"

@interface MITCollectionViewGridLayout ()
@property (nonatomic,strong) NSMutableDictionary *sectionLayouts;
@property (nonatomic) CGFloat dividerDecorationWidth;

@property (nonatomic) CGFloat columnWidth;
@property (nonatomic) CGFloat interItemPadding;
@property (nonatomic,strong) NSMutableDictionary *cachedItemHeights;
@end

@implementation MITCollectionViewGridLayout
@synthesize columnWidth = _columnWidth;
@synthesize interItemPadding = _interItemPadding;

@dynamic collectionViewDelegate;

- (instancetype)init
{
    self = [super init];

    if (self) {
        _itemHeight = 128.;
        _headerHeight = 0;
        _numberOfColumns = 5;
        _sectionLayouts = [[NSMutableDictionary alloc] init];

        _dividerDecorationWidth = 5.0;
        _minimumInterItemPadding = 60.0;
        _lineSpacing = 15.0;
        _sectionInsets = UIEdgeInsetsMake(20, 60, 10, 60);

        [self registerNib:[UINib nibWithNibName:@"GridDividerView" bundle:nil] forDecorationViewOfKind:MITNewsReusableViewIdentifierDivider];
    }

    return self;
}


#pragma mark Properties
- (id<MITCollectionViewDelegateNewsGrid>)collectionViewDelegate
{
    id<UICollectionViewDelegate> collectionViewDelegate = self.collectionView.delegate;

    if ([collectionViewDelegate conformsToProtocol:@protocol(MITCollectionViewDelegateNewsGrid)]) {
        return (id<MITCollectionViewDelegateNewsGrid>)collectionViewDelegate;
    } else {
        return nil;
    }
}

#pragma mark UICollectionViewLayout overrides
- (void)prepareLayout
{
    NSRange sectionRange = NSMakeRange(0, [self.collectionView numberOfSections]);

    // Perform a sanity check of our data source before attempting to lay things out
    [[NSIndexSet indexSetWithIndexesInRange:sectionRange] enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        const NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        const NSUInteger numberOfColumns  = [self numberOfColumnsInSection:section];
        const NSUInteger featuredHorizontalSpan = [self featuredStoryHorizontalSpanInSection:section];
        const NSUInteger featuredVerticalSpan = [self featuredStoryVerticalSpanInSection:section];
        const MITCollectionViewGridSpan span = MITCollectionViewGridSpanMake(featuredHorizontalSpan, featuredVerticalSpan);

        // At a minimum, we need at least N - 1 filled rows (where N is the vertical span of the
        // featured item cell), plus a final cell on the Nth row so we can get a valid height
        NSUInteger minimumNumberOfItems = 0;
        if (MITCollectionViewGridSpanIsValid(span)) {
            minimumNumberOfItems = ((numberOfColumns - featuredHorizontalSpan) * (featuredVerticalSpan - 1)) + 1;
        }

        if (minimumNumberOfItems > numberOfItems) {
            DDLogError(@"layout may fail: section %lu requires at least %ld items to present a %ldx%ld spanning cell, only %ld items in section", (unsigned long)section, (unsigned long)minimumNumberOfItems, (unsigned long)span.horizontal, (unsigned long)span.vertical, (unsigned long)numberOfItems);
        }
    }];
}

- (MITCollectionViewGridLayoutSection*)layoutForSection:(NSInteger)section
{
    MITCollectionViewGridLayoutSection *sectionLayout = self.sectionLayouts[@(section)];

    if (!sectionLayout) {
        sectionLayout = [self _layoutForSection:section];
        NSAssert(sectionLayout,@"failed to create layout for section %ld",(long)section);
        self.sectionLayouts[@(section)] = sectionLayout;
    }

    return sectionLayout;
}

- (MITCollectionViewGridLayoutSection*)_layoutForSection:(NSInteger)section
{
    NSUInteger numberOfColumns = [self numberOfColumnsInSection:section];
    MITCollectionViewGridLayoutSection *sectionLayout = [MITCollectionViewGridLayoutSection sectionWithIndex:section layout:self numberOfColumns:numberOfColumns];
    sectionLayout.frame = [self _layoutFrameForSection:section];

    const NSUInteger featuredHorizontalSpan = [self featuredStoryHorizontalSpanInSection:section];
    const NSUInteger featuredVerticalSpan = [self featuredStoryVerticalSpanInSection:section];
    sectionLayout.featuredItemSpan = MITCollectionViewGridSpanMake(featuredHorizontalSpan, featuredVerticalSpan);
    sectionLayout.minimumInterItemPadding = self.minimumInterItemPadding;
    sectionLayout.lineSpacing = self.lineSpacing;

    return sectionLayout;
}

- (CGSize)collectionViewContentSize
{
    __block CGRect contentFrame = CGRectZero;
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numberOfSections; ++section) {
        MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:section];

        if (section == 0) {
            contentFrame = sectionLayout.frame;
        } else {
            contentFrame = CGRectUnion(contentFrame, sectionLayout.frame);
        }
    }

    contentFrame.size.height += _sectionInsets.top + _sectionInsets.bottom;
    return contentFrame.size;
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    // Not optimal since this is still relatively expensive
    // but not as bad since we aren't nuking all the heights
    [self.sectionLayouts removeAllObjects];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context
{
    [super invalidateLayoutWithContext:context];

    if (context.invalidateEverything || context.invalidateDataSourceCounts) {
        [self.cachedItemHeights removeAllObjects];
        [self.sectionLayouts removeAllObjects];
    } else {
        [self.sectionLayouts enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, MITCollectionViewGridLayoutSection *layout, BOOL *stop) {
            layout.frame = [self _layoutFrameForSection:[key unsignedIntegerValue]];
        }];
    }
}

- (CGRect)_layoutFrameForSection:(NSUInteger)section
{
    CGRect layoutBounds = self.collectionView.bounds;
    layoutBounds.origin = CGPointZero;

    // Set the height to zero since it will be variable (this is a
    // vertically scrolling layout).
    layoutBounds.size.height = 0;

    if (section == 0) {
        CGRect frame = layoutBounds;
        return UIEdgeInsetsInsetRect(frame, self.sectionInsets);
    } else {
        MITCollectionViewGridLayoutSection *previousSectionLayout = [self layoutForSection:section - 1];
        CGRect frame = layoutBounds;
        frame.origin.y = CGRectGetMaxY(previousSectionLayout.frame) + self.sectionInsets.bottom;
        return UIEdgeInsetsInsetRect(frame, self.sectionInsets);
    }
}

#pragma mark Returning layout attributes
- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableOrderedSet *visibleLayoutAttributes = [[NSMutableOrderedSet alloc] init];
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numberOfSections; ++section) {
        MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:section];

        if (CGRectIntersectsRect(rect, sectionLayout.frame)) {
            [sectionLayout.itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                }
            }];

            [sectionLayout.decorationLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                }
            }];

            CGPoint contentOffset = self.collectionView.contentOffset;
            UICollectionViewLayoutAttributes *headerLayoutAttributes = [sectionLayout headerLayoutAttributesWithContentOffset:contentOffset];
            if (headerLayoutAttributes) {
                [visibleLayoutAttributes addObject:headerLayoutAttributes];
            }
        }
    }

    return [visibleLayoutAttributes array];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBound
{
    return YES;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:indexPath.section];
    return [sectionLayout headerLayoutAttributesWithContentOffset:self.collectionView.contentOffset];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString*)decorationViewKind atIndexPath:(NSIndexPath *)indexPath
{
    MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:indexPath.section];

    __block UICollectionViewLayoutAttributes *attributes = nil;
    [[sectionLayout decorationLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes* layoutAttributes, NSUInteger idx, BOOL *stop) {
        if ([layoutAttributes.representedElementKind isEqualToString:decorationViewKind]) {
            if ([layoutAttributes.indexPath isEqual:indexPath]) {
                attributes = layoutAttributes;
                (*stop) = YES;
            }
        }
    }];

    return attributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath) {
        return nil;
    }

    MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:indexPath.section];
    UICollectionViewLayoutAttributes *layoutAttributes = [sectionLayout layoutAttributesForItemAtIndexPath:indexPath];
    NSAssert(layoutAttributes, @"no layout attributes for index path %@",indexPath);
    return layoutAttributes;
}

#pragma mark Cache Properties
- (NSMutableDictionary*)cachedItemHeights
{
    if (!_cachedItemHeights) {
        _cachedItemHeights = [[NSMutableDictionary alloc] init];
    }
    
    return _cachedItemHeights;
}


#pragma mark Delegate Pass-Thru
- (NSUInteger)numberOfColumnsInSection:(NSInteger)section
{
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:numberOfColumnsInSection:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self numberOfColumnsInSection:section];
    } else {
        return self.numberOfColumns;
    }
}

- (CGFloat)heightForHeaderInSection:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:section];
    if (!self.cachedItemHeights[indexPath]) {
        CGFloat headerHeight = self.headerHeight;
        
        if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:withWidth:)]) {
            headerHeight = [self.collectionViewDelegate collectionView:self.collectionView layout:self heightForHeaderInSection:section withWidth:CGRectGetWidth(self.collectionView.bounds)];
        }
        
        self.cachedItemHeights[indexPath] = @(headerHeight);
    }
    
    return [self.cachedItemHeights[indexPath] doubleValue];
}

- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath
{
    if (!self.cachedItemHeights[indexPath]) {
        CGFloat itemHeight = self.itemHeight;
        
        if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:withWidth:)]) {
            MITCollectionViewGridLayoutSection *section = [self layoutForSection:indexPath.section];
            itemHeight = [self.collectionViewDelegate collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath withWidth:section.columnWidth];
        }
        
        self.cachedItemHeights[indexPath] = @(itemHeight);
    }
    
    return [self.cachedItemHeights[indexPath] doubleValue];
}

- (NSUInteger)featuredStoryHorizontalSpanInSection:(NSInteger)section
{
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:featuredStoryHorizontalSpanInSection:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self featuredStoryHorizontalSpanInSection:section];
    } else {
        return 0;
    }
}

- (NSUInteger)featuredStoryVerticalSpanInSection:(NSInteger)section
{
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:featuredStoryVerticalSpanInSection:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self featuredStoryVerticalSpanInSection:section];
    } else {
        return 0;
    }
}

@end
