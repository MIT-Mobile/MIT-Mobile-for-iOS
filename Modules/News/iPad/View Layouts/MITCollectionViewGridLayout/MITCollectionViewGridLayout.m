#import "MITCollectionViewGridLayout.h"
#import "MITCollectionViewGridLayoutSection.h"
#import "MITNewsConstants.h"
#import "MITCollectionViewGridDividerView.h"

@interface MITCollectionViewGridLayout ()
@property (nonatomic,strong) NSMutableDictionary *sectionLayouts;
@property (nonatomic) CGFloat dividerDecorationWidth;
@end

@implementation MITCollectionViewGridLayout
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
        _minimumInterItemPadding = 8.0;
        _lineSpacing = 8.0;
        _sectionInsets = UIEdgeInsetsMake(0, 30, 10, 30);

        [self registerClass:[MITCollectionViewGridDividerView class] forDecorationViewOfKind:MITNewsReusableViewIdentifierDivider];
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
            NSString *message = [NSString stringWithFormat:@"section %d requires at least %d items to present a %dx%d spanning cell, only %d items in section",section,minimumNumberOfItems,span.horizontal,span.vertical,numberOfItems];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:message userInfo:nil];
        }
    }];
}

- (MITCollectionViewGridLayoutSection*)layoutForSection:(NSInteger)section
{
    MITCollectionViewGridLayoutSection *sectionLayout = self.sectionLayouts[@(section)];

    if (!sectionLayout) {
        sectionLayout = [self _layoutForSection:section];
        NSAssert(sectionLayout,@"failed to create layout for section %d",section);
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

    return contentFrame.size;
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    // TODO: Handle invalidation better. There shouldn't be too many items
    // (500 max per category) so this won't be a huge processor hog
    // but it's less than ideal and makes animation difficult.
    // (bskinner - 2014.07.16)
    [self.sectionLayouts removeAllObjects];
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
            [[sectionLayout itemLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                }
            }];

            [[sectionLayout decorationLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
                if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                }
            }];

            CGPoint contentOffset = self.collectionView.contentOffset;
            contentOffset.y += self.collectionView.contentInset.top;
            contentOffset.x += self.collectionView.contentInset.left;
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
    return sectionLayout.headerLayoutAttributes;
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
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:heightForHeaderInSection:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self heightForHeaderInSection:section];
    } else {
        return self.headerHeight;
    }
}

- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath];
    } else {
        return self.itemHeight;
    }
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
