#import "MITCollectionViewNewsGridLayout.h"
#import "MITCollectionViewGridLayoutSection.h"
#import "MITNewsConstants.h"

@interface MITCollectionViewNewsGridLayout ()
@property (nonatomic,strong) NSMutableDictionary *sectionLayouts;
@property (nonatomic) CGFloat dividerDecorationWidth;
@end

@implementation MITCollectionViewNewsGridLayout
@dynamic collectionViewDelegate;

- (instancetype)init
{
    self = [super init];

    if (self) {
        _itemHeight = 128.;
        _headerHeight = 0;
        _numberOfColumns = 4;
        _sectionLayouts = [[NSMutableDictionary alloc] init];

        _dividerDecorationWidth = 5.0;
        _minimumInterItemPadding = 8.0;
        _lineSpacing = 8.0;
        _sectionSpacing = 20.;
        [self registerClass:[UICollectionViewCell class] forDecorationViewOfKind:MITNewsCollectionDecorationDividerIdentifier];
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
    // Do Nothing, etc
}

- (MITCollectionViewGridLayoutSection*)layoutForSection:(NSInteger)section
{
    MITCollectionViewGridLayoutSection *sectionLayout = self.sectionLayouts[@(section)];

    if (!sectionLayout) {
        sectionLayout = [self primitiveLayoutForSection:section];
        NSAssert(sectionLayout,@"failed to create layout for section %d",section);
        self.sectionLayouts[@(section)] = sectionLayout;
    }

    return sectionLayout;
}

- (MITCollectionViewGridLayoutSection*)primitiveLayoutForSection:(NSInteger)section
{
    MITCollectionViewGridLayoutSection *sectionLayout = [MITCollectionViewGridLayoutSection sectionWithLayout:self forSection:section numberOfColumns:self.numberOfColumns];

    CGPoint origin = CGPointZero;
    if (section > 0) {
        MITCollectionViewGridLayoutSection *previousSectionLayout = [self layoutForSection:section - 1];
        CGRect frame = previousSectionLayout.frame;
        origin = CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) + self.sectionSpacing);
    }

    sectionLayout.contentInsets = UIEdgeInsetsMake(0, 30., 0, 30.);
    CGRect sectionFrame = CGRectMake(origin.x, origin.y, CGRectGetWidth(self.collectionView.bounds), 0);
    sectionLayout.frame = sectionFrame;

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

    [self.sectionLayouts enumerateKeysAndObjectsUsingBlock:^(NSNumber *section, MITCollectionViewGridLayoutSection *sectionLayout, BOOL *stop) {
        [sectionLayout invalidateLayout];
    }];
}

#pragma mark Returning layout attributes
- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableOrderedSet *visibleLayoutAttributes = [[NSMutableOrderedSet alloc] init];
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSInteger section = 0; section < numberOfSections; ++section) {
        MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:section];

        if (CGRectIntersectsRect(rect, sectionLayout.frame)) {
            [[sectionLayout allLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
                if ([layoutAttributes.representedElementKind isEqualToString:MITNewsStoryHeaderReusableView]) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                } else if (CGRectIntersectsRect(rect, layoutAttributes.frame)) {
                    [visibleLayoutAttributes addObject:layoutAttributes];
                }
            }];
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
    return nil;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITCollectionViewGridLayoutSection *sectionLayout = [self layoutForSection:indexPath.section];
    return [sectionLayout layoutAttributesForItemAtIndexPath:indexPath];
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

- (BOOL)showFeaturedItemInSection:(NSInteger)section
{
    if ([self.collectionViewDelegate respondsToSelector:@selector(collectionView:layout:showFeaturedItemInSection:)]) {
        return [self.collectionViewDelegate collectionView:self.collectionView layout:self showFeaturedItemInSection:section];
    } else {
        return NO;
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
