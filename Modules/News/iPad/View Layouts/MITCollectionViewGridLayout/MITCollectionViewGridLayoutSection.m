#import "MITCollectionViewGridLayoutSection.h"
#import "MITCollectionViewNewsGridLayout.h"
#import "MITCollectionViewGridLayoutRow.h"
#import "MITNewsConstants.h"

typedef struct {
    MITCollectionViewGridSpan span;
    CGFloat width;
    CGFloat horizontalOffset;
} MITSpannedItemContext;

static MITSpannedItemContext const MITSpannedItemEmptyContext = {.span = {.horizontal = 0, .vertical = 0}, .width = 0, .horizontalOffset = 0};

MITCollectionViewGridSpan const MITCollectionViewGridSpanInvalid = {.horizontal = 0, .vertical = 0};
BOOL MITCollectionViewGridSpanIsValid(MITCollectionViewGridSpan span) {
    return (BOOL)((span.horizontal != 0) && (span.vertical != 0));
}

MITCollectionViewGridSpan MITCollectionViewGridSpanMake(NSUInteger horizontal, NSUInteger vertical) {
    MITCollectionViewGridSpan span = {.horizontal = horizontal, .vertical = vertical};
    return span;
}

@interface MITCollectionViewGridLayoutSection ()
@property (nonatomic) NSInteger section;
@property (nonatomic) CGPoint origin;
@property (nonatomic) NSUInteger numberOfColumns;

@end

@implementation MITCollectionViewGridLayoutSection {
    BOOL _needsLayout;
}

@synthesize bounds = _bounds;
@synthesize decorationLayoutAttributes = _decorationLayoutAttributes;
@synthesize featuredItemLayoutAttributes = _featuredItemLayoutAttributes;
@synthesize headerLayoutAttributes = _headerLayoutAttributes;
@synthesize layout = _layout;
@synthesize itemLayoutAttributes = _itemLayoutAttributes;
@synthesize section = _section;

@dynamic frame;

+ (instancetype)sectionWithIndex:(NSUInteger)section layout:(MITCollectionViewNewsGridLayout*)layout numberOfColumns:(NSInteger)numberOfColumns
{
    MITCollectionViewGridLayoutSection *sectionLayout = [[self alloc] initWithSection:section layout:layout];
    sectionLayout.numberOfColumns = numberOfColumns;

    return sectionLayout;
}

- (instancetype)initWithSection:(NSUInteger)section layout:(MITCollectionViewNewsGridLayout *)layout
{
    self = [super init];
    if (self) {
        _section = section;
        _layout = layout;
        _numberOfColumns = 3;
        _stickyHeaders = YES;
        [self invalidateLayout];
    }

    return self;
}

- (void)setNumberOfColumns:(NSUInteger)numberOfColumns
{
    if (numberOfColumns < 2) {
        _numberOfColumns = 2;
    } else {
        _numberOfColumns = numberOfColumns;
    }
}

- (UICollectionViewLayoutAttributes*)featuredItemLayoutAttributes
{
    [self layoutIfNeeded];
    
    UICollectionViewLayoutAttributes *featuredItemLayoutAttributes = _featuredItemLayoutAttributes;
    
    if (featuredItemLayoutAttributes) {
        featuredItemLayoutAttributes = [_featuredItemLayoutAttributes copy];
        featuredItemLayoutAttributes.frame = CGRectOffset(featuredItemLayoutAttributes.frame, self.origin.x, self.origin.y);
    }
    
    return featuredItemLayoutAttributes;
}

- (UICollectionViewLayoutAttributes*)headerLayoutAttributes
{
    [self layoutIfNeeded];
    
    UICollectionViewLayoutAttributes *headerLayoutAttributes = nil;
    if (_headerLayoutAttributes) {
        headerLayoutAttributes = [_headerLayoutAttributes copy];
        headerLayoutAttributes.frame = CGRectOffset(headerLayoutAttributes.frame, self.origin.x, self.origin.y);
    }
    
    return headerLayoutAttributes;
}

- (UICollectionViewLayoutAttributes*)headerLayoutAttributesWithContentOffset:(CGPoint)contentOffset
{
    UICollectionViewLayoutAttributes *headerLayoutAttributes = self.headerLayoutAttributes;

    if (self.stickyHeaders) {
        const CGRect sectionFrame = self.frame;
        const CGRect headerFrame = headerLayoutAttributes.frame;

        const CGFloat maximumHeaderOffset = CGRectGetHeight(sectionFrame) - CGRectGetHeight(headerFrame);
        if (contentOffset.y < CGRectGetMinY(sectionFrame)) {
            // If the current content offset is above the current section, reset the
            // transform to the identity, just in case, and leave it pinned to the top
            // of the section
            headerLayoutAttributes.transform = CGAffineTransformIdentity;
        } else if (contentOffset.y > CGRectGetMaxY(sectionFrame)) {
            // If the current content offset is below the current section,
            // pin the header to the bottom of the section so we get proper
            // behavior when scrolling between sectons (ie: the header doesn't
            // jump around)
            headerLayoutAttributes.transform = CGAffineTransformMakeTranslation(0, maximumHeaderOffset);
        } else {
            // Otherwise, the content offset is somewhere within the current section frame.
            // Figure out what the current offset is from the frame's minY and adjust the
            // translation as needed.
            CGFloat contentOffsetFromTopOfFrame = contentOffset.y - CGRectGetMinY(sectionFrame);

            // Make sure the header doesn't extent past the current section frame
            CGFloat headerOffset = MIN(contentOffsetFromTopOfFrame,maximumHeaderOffset);
            headerLayoutAttributes.transform = CGAffineTransformMakeTranslation(0, headerOffset);
        }
    }

    return headerLayoutAttributes;
}

- (NSArray*)itemLayoutAttributes
{
    [self layoutIfNeeded];
    
    if (!_itemLayoutAttributes) {
        return nil;
    } else {
        NSMutableArray *itemLayoutAttributes = [[NSMutableArray alloc] initWithArray:_itemLayoutAttributes copyItems:YES];
        [itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
            layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, self.origin.x, self.origin.y);
        }];

        UICollectionViewLayoutAttributes *featuredItemLayoutAttributes = self.featuredItemLayoutAttributes;
        if (featuredItemLayoutAttributes) {
            [itemLayoutAttributes addObject:featuredItemLayoutAttributes];
        }
        
        return itemLayoutAttributes;
    }
}

- (NSArray*)decorationLayoutAttributes
{
    [self layoutIfNeeded];

    if (!_decorationLayoutAttributes) {
        return nil;
    } else {
        NSArray *decorationLayoutAttributes = [[NSArray alloc] initWithArray:_decorationLayoutAttributes copyItems:YES];
        [decorationLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
            layoutAttributes.frame = CGRectOffset(layoutAttributes.frame, self.origin.x, self.origin.y);
        }];

        return decorationLayoutAttributes;
    }
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
        _needsLayout = YES;
    }
}

- (void)invalidateLayout
{
    _featuredItemLayoutAttributes = nil;
    _headerLayoutAttributes = nil;
    _itemLayoutAttributes = nil;
    _bounds.size.height = 0;
    _needsLayout = YES;
}

- (void)layoutIfNeeded
{
    const NSUInteger numberOfItems = [self.layout.collectionView numberOfItemsInSection:self.section];
    if (numberOfItems == 0) {
        // Nothing to layout so just mark the layout as up-to-date
        // and bail.
        _needsLayout = NO;
        return;
    }

    if (_needsLayout) {
        // When performing the layout, assume we have an infinite vertical canvas to work with.
        // Once everything is laid out, we'll go back and give the heights a correct value
        const NSInteger numberOfColumns = self.numberOfColumns;

        // Apply the content insets to the actual content so things appear properly. We only care
        //  about the left and right insets here. The top will be ignored and the
        //  bottom will be handled after everything is laid out.
        __block CGRect layoutBounds = _bounds;
        layoutBounds.size.height = CGFLOAT_MAX;

        UICollectionViewLayoutAttributes *headerLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MITNewsReusableViewIdentifierSectionHeader withIndexPath:[NSIndexPath indexPathWithIndex:self.section]];
        
        CGRect headerFrame = CGRectZero;
        CGFloat headerHeight = [self.layout heightForHeaderInSection:self.section];
        CGRectDivide(layoutBounds, &headerFrame, &layoutBounds, headerHeight, CGRectMinYEdge);
        headerLayoutAttributes.frame = headerFrame;

        // Set a high value for the zIndex to make sure that the header 'floats'
        // over everything else.
        headerLayoutAttributes.zIndex = 1024;
        _headerLayoutAttributes = headerLayoutAttributes;

        const CGFloat minimumInterItemPadding = 2 * floor(self.layout.minimumInterItemPadding / 2.0) + 1;
        CGFloat maximumPaddingPerRow = (minimumInterItemPadding * (numberOfColumns - 1));
        const CGFloat columnWidth = floor((CGRectGetWidth(layoutBounds) - maximumPaddingPerRow) / numberOfColumns);


        MITSpannedItemContext featuredItemLayoutContext = MITSpannedItemEmptyContext;
        const BOOL hasFeaturedItem = MITCollectionViewGridSpanIsValid(self.featuredItemSpan);
        if (hasFeaturedItem) {
            featuredItemLayoutContext.span = self.featuredItemSpan;

            if (featuredItemLayoutContext.span.horizontal > 0) {
                // The actual content of the featured item will span <n> column widths
                //  plus <n-1> item spacings. The extra minimumInterItemPadding factor
                //  here is so we leave the proper spacing between the edge of the featured
                //  item and the rows it overlaps
                featuredItemLayoutContext.width = columnWidth * featuredItemLayoutContext.span.horizontal;
                featuredItemLayoutContext.width += minimumInterItemPadding * (featuredItemLayoutContext.span.horizontal - 1);
                featuredItemLayoutContext.horizontalOffset = featuredItemLayoutContext.width + minimumInterItemPadding;
            }

            NSAssert(featuredItemLayoutContext.span.horizontal < self.numberOfColumns, @"there must be space for at least 1 item after the featured story", self.numberOfColumns);
        }
        
        
        // First layout pass. This allocates the items to each row,
        //  making sure to leave a space for the featured item
        //  (if present). This pass also sets the height of each row
        //  and allows us to position each row's origin in the second pass
        MITCollectionViewGridLayoutRow *currentLayoutRow = nil;
        NSMutableArray *rowLayouts = [[NSMutableArray alloc] init];
        NSUInteger (^numberOfRows)(void) = ^{ return [rowLayouts count]; };
        
        NSInteger item = 0;
        if (hasFeaturedItem) {
            ++item; // The featured item is always item 0, so start at item 1 if a featured item is present
        }

        for (; item < numberOfItems; ++item) {
            NSIndexPath* const indexPath = [NSIndexPath indexPathForItem:item inSection:self.section];
            NSUInteger maximumNumberOfItemsInRow = numberOfColumns;

            // If the row we are laying out overlaps the featured story, make sure to reduce the number
            // of items it is capable of holding
            if (numberOfRows() < featuredItemLayoutContext.span.vertical) {
                maximumNumberOfItemsInRow -= featuredItemLayoutContext.span.horizontal;
            }

            if (!currentLayoutRow || ([currentLayoutRow numberOfItems] >= maximumNumberOfItemsInRow)) {
                if (currentLayoutRow) {
                    [rowLayouts addObject:currentLayoutRow];
                }

                // Recalculate the maximum number of items in the new row
                // since we just added the old one to the saved rows and it's
                // time to start on a new one.
                if (numberOfRows() < featuredItemLayoutContext.span.vertical) {
                    maximumNumberOfItemsInRow = numberOfColumns - featuredItemLayoutContext.span.horizontal;
                } else {
                    maximumNumberOfItemsInRow = numberOfColumns;
                }

                currentLayoutRow = [[MITCollectionViewGridLayoutRow alloc] init];
                currentLayoutRow.interItemSpacing = minimumInterItemPadding;
                currentLayoutRow.maximumNumberOfItems = maximumNumberOfItemsInRow;

                // Make sure a frame with a valid width is set here. We don't care about the origin
                // or the height at this point (the height will be ignored, anyway) but the width
                // is vital, otherwise we'll get an incorrect height when calculating the featured item
                // placement
                CGRect initialRowFrame = CGRectMake(CGRectGetMinX(layoutBounds), 0, CGRectGetWidth(layoutBounds), 0);
                if (numberOfRows() < featuredItemLayoutContext.span.vertical) {
                    initialRowFrame.origin.x += featuredItemLayoutContext.horizontalOffset;
                    initialRowFrame.size.width -= featuredItemLayoutContext.horizontalOffset;
                }

                currentLayoutRow.frame = initialRowFrame;
            }
            
            CGFloat itemHeight = [self.layout heightForItemAtIndexPath:indexPath];
            [currentLayoutRow addItemForIndexPath:indexPath withHeight:itemHeight];
        }

        if (currentLayoutRow) {
            [rowLayouts addObject:currentLayoutRow];
        }

        // Now that the rows have their items partitioned out we can figure out how high
        // the featured item should be (and position it). One thing to note is that if an
        // invalid frame or a frame with an improper width is assigned to the row when
        // paritioning the elements, the results here will be interesting.
        if (hasFeaturedItem) {
            UICollectionViewLayoutAttributes *featuredItemLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.section]];

            __block CGFloat featuredItemHeight = 0;
            [rowLayouts enumerateObjectsUsingBlock:^(MITCollectionViewGridLayoutRow *rowLayout, NSUInteger idx, BOOL *stop) {
                if (idx < featuredItemLayoutContext.span.vertical) {
                    featuredItemHeight += CGRectGetHeight(rowLayout.frame);
                } else {
                    (*stop) = YES;
                }
            }];

            featuredItemHeight += (featuredItemLayoutContext.span.horizontal - 1) * self.layout.lineSpacing;

            CGRect featuredItemFrame = CGRectZero;
            CGRect scratchFrame = CGRectZero;
            CGRectDivide(layoutBounds, &featuredItemFrame, &scratchFrame, featuredItemHeight, CGRectMinYEdge);
            CGRectDivide(featuredItemFrame, &featuredItemFrame, &scratchFrame, featuredItemLayoutContext.width, CGRectMinXEdge);

            featuredItemLayoutAttributes.frame = featuredItemFrame;
            _featuredItemLayoutAttributes = featuredItemLayoutAttributes;
        } else {
            _featuredItemLayoutAttributes = nil;
        }

        // At this point, the rows been paritioned off and their hights should be fixed
        // but they are bunched up at the top. Run through each of the rows here and
        // shift the origins to where they need to be
        NSMutableArray *itemLayoutAttributes = [[NSMutableArray alloc] init];
        NSMutableArray *decorationLayoutAttributes = [[NSMutableArray alloc] init];
        [rowLayouts enumerateObjectsUsingBlock:^(MITCollectionViewGridLayoutRow *row, NSUInteger index, BOOL *stop) {
            CGRect bounds = row.bounds;
            CGRect frame = CGRectZero;
            CGRectDivide(layoutBounds, &frame, &layoutBounds, CGRectGetHeight(bounds), CGRectMinYEdge);

            CGRect scratchFrame = CGRectZero;
            if (index < featuredItemLayoutContext.span.vertical) {
                CGRectDivide(frame, &scratchFrame, &frame, featuredItemLayoutContext.horizontalOffset, CGRectMinXEdge);
            }

            row.frame = frame;

            [itemLayoutAttributes addObjectsFromArray:[row itemLayoutAttributes]];
            [decorationLayoutAttributes addObjectsFromArray:[row decorationLayoutAttributes]];

            // Shift the layout bounds down a bit further to account for the intraLineSpacing
            // if we are not on the (n-1)th row;
            NSRange spacingIndexRange = NSMakeRange(0, numberOfRows() - 1);
            NSIndexSet *spacingIndexes = [NSIndexSet indexSetWithIndexesInRange:spacingIndexRange];
            if ([spacingIndexes containsIndex:index]) {
                CGRect scratchRect = CGRectZero;
                CGRectDivide(layoutBounds, &scratchRect, &layoutBounds, self.layout.lineSpacing, CGRectMinYEdge);
            }
        }];
        
        MITCollectionViewGridLayoutRow *lastRowLayout = [rowLayouts lastObject];
        _bounds.size.height = CGRectGetMaxY(lastRowLayout.frame);
        _itemLayoutAttributes = itemLayoutAttributes;

        if (hasFeaturedItem) {
            NSMutableArray *allLayoutAttributes = [[NSMutableArray alloc] init];
            if (hasFeaturedItem) {
                [allLayoutAttributes addObject:_featuredItemLayoutAttributes];
            }

            [allLayoutAttributes addObjectsFromArray:_itemLayoutAttributes];

            _decorationLayoutAttributes = [self _featuredDecorationLayoutAttributesForItemLayoutAttributes:allLayoutAttributes withBounds:_bounds];
        } else {
            _decorationLayoutAttributes = decorationLayoutAttributes;
        }

        _needsLayout = NO;
    }
}

- (NSArray*)_featuredDecorationLayoutAttributesForItemLayoutAttributes:(NSArray*)itemLayoutAttributes withBounds:(CGRect)bounds
{
    if (!itemLayoutAttributes) {
        return nil;
    }

    NSMutableDictionary *allDecorationLayoutAttributes = [[NSMutableDictionary alloc] init];

    [itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *layoutAttributes, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *nextLayoutAttributes = nil;
        if ((idx + 1) < [itemLayoutAttributes count]) {
            nextLayoutAttributes = itemLayoutAttributes[idx + 1];
        }

        const CGFloat decorationOriginX = CGRectGetMaxX(layoutAttributes.frame);
        if (!allDecorationLayoutAttributes[@(decorationOriginX)]) {
            // Make sure we are not at the end of the current row
            if (CGRectGetMinY(layoutAttributes.frame) != CGRectGetMinY(nextLayoutAttributes.frame)) {
                return;
            }

            const CGFloat decorationOriginY = CGRectGetMinY(layoutAttributes.frame);
            const CGFloat decorationWidth = CGRectGetMinX(nextLayoutAttributes.frame) - decorationOriginX;
            const CGFloat decorationHeight = CGRectGetHeight(layoutAttributes.frame);

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:layoutAttributes.indexPath.item inSection:self.section];
            UICollectionViewLayoutAttributes *decorationLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:MITNewsCollectionDecorationDividerIdentifier withIndexPath:indexPath];

            decorationLayoutAttributes.frame = CGRectMake(decorationOriginX, decorationOriginY, decorationWidth, decorationHeight);
            allDecorationLayoutAttributes[@(decorationOriginX)] = decorationLayoutAttributes;
        } else {
            UICollectionViewLayoutAttributes *decorationLayoutAttributes = allDecorationLayoutAttributes[@(decorationOriginX)];
            CGRect frame = decorationLayoutAttributes.frame;
            frame.size.height += CGRectGetMaxY(layoutAttributes.frame) - CGRectGetMaxY(decorationLayoutAttributes.frame);
            decorationLayoutAttributes.frame = frame;
        }
    }];

    return [allDecorationLayoutAttributes allValues];
}

- (NSArray*)allLayoutAttributes
{
    NSMutableArray *allLayoutAttributes = [[NSMutableArray alloc] init];

    if (_headerLayoutAttributes) {
        [allLayoutAttributes addObject:self.headerLayoutAttributes];
    }

    if (_featuredItemLayoutAttributes) {
        [allLayoutAttributes addObject:self.featuredItemLayoutAttributes];
    }

    if (_itemLayoutAttributes) {
        [allLayoutAttributes addObjectsFromArray:self.itemLayoutAttributes];
    }

    if (_decorationLayoutAttributes) {
        [allLayoutAttributes addObjectsFromArray:self.decorationLayoutAttributes];
    }

    return allLayoutAttributes;
}

- (NSArray*)_allLayoutAttributes
{
    NSMutableArray *allLayoutAttributes = [[NSMutableArray alloc] init];

    if (_headerLayoutAttributes) {
        [allLayoutAttributes addObject:_headerLayoutAttributes];
    }

    if (_featuredItemLayoutAttributes) {
        [allLayoutAttributes addObject:_featuredItemLayoutAttributes];
    }

    if (_itemLayoutAttributes) {
        [allLayoutAttributes addObjectsFromArray:_itemLayoutAttributes];
    }

    if (_decorationLayoutAttributes) {
        [allLayoutAttributes addObjectsFromArray:_decorationLayoutAttributes];
    }

    return allLayoutAttributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath
{
    __block UICollectionViewLayoutAttributes *resultLayoutAttributes = nil;
    [[self _allLayoutAttributes] enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
        if (attributes.representedElementCategory == UICollectionElementCategoryCell) {
            if ([attributes.indexPath isEqual:indexPath]) {
                resultLayoutAttributes = attributes;
                (*stop) = YES;
            }
        }
    }];
    
    resultLayoutAttributes = [resultLayoutAttributes copy];
    resultLayoutAttributes.frame = CGRectOffset(resultLayoutAttributes.frame, self.origin.x, self.origin.y);
    
    return resultLayoutAttributes;
}

@end
