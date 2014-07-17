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
@property (nonatomic,getter = isFeatured) BOOL featured;
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
        _featured = NO;
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

    if (!headerLayoutAttributes) {
        return nil;
    } else if (self.stickyHeaders) {
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
    }
}

- (void)invalidateLayout
{
    _featuredItemLayoutAttributes = nil;
    _headerLayoutAttributes = nil;
    _itemLayoutAttributes = nil;
    _decorationLayoutAttributes = nil;
    _bounds.size.height = 0;
    _needsLayout = YES;
}

- (void)layoutIfNeeded
{
    if (_needsLayout) {
        // When performing the layout, assume we have an infinite vertical canvas to work with.
        // Once everything is laid out, we'll go back and give the heights a correct value
        const NSInteger numberOfColumns = self.numberOfColumns;
        const NSUInteger numberOfItems = [self.layout.collectionView numberOfItemsInSection:self.section];

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


        if (numberOfItems == 0) {
            // Nothing to layout so just mark the layout as up-to-date
            // and bail.
            _needsLayout = NO;
            return;
        }

        const CGFloat minimumInterItemPadding = 2 * floor(self.layout.minimumInterItemPadding / 2.0) + 1;
        CGFloat maximumPaddingPerRow = (minimumInterItemPadding * (numberOfColumns - 1));
        const CGFloat columnWidth = floor((CGRectGetWidth(layoutBounds) - maximumPaddingPerRow) / numberOfColumns);


        MITSpannedItemContext featuredItemLayoutContext = MITSpannedItemEmptyContext;
        self.featured = MITCollectionViewGridSpanIsValid(self.featuredItemSpan);
        if (self.isFeatured) {
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
        if (self.isFeatured) {
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

            // Check to see if we need to create a new row layout helper. This should be triggered
            // if we try to march through here with either a filled or non-existant row.
            if ((currentLayoutRow == nil) || currentLayoutRow.isFilled) {
                if (currentLayoutRow) {
                    [rowLayouts addObject:currentLayoutRow];
                }

                // Recalculate the maximum number of items in the new row
                // since we just added the old one to the saved rows (if there was one)
                // and it's time to start on a new one.
                if (numberOfRows() < featuredItemLayoutContext.span.vertical) {
                    // If the row would overlap the featured item's space, reduce the
                    // number of items we can insert by the number of columns the item spans.
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
                // placement, or place items over/under the featured item.
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
        if (self.isFeatured) {
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

            // Shift the layout bounds down a bit further to account for the line spacing
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


        NSMutableArray *allLayoutAttributes = [[NSMutableArray alloc] init];
        if (_featuredItemLayoutAttributes) {
            [allLayoutAttributes addObject:_featuredItemLayoutAttributes];
        }

        [allLayoutAttributes addObjectsFromArray:_itemLayoutAttributes];
        _decorationLayoutAttributes = [self _featuredDecorationLayoutAttributesForItemLayoutAttributes:allLayoutAttributes withBounds:_bounds];

        _needsLayout = NO;
    }
}

- (NSArray*)_featuredDecorationLayoutAttributesForItemLayoutAttributes:(NSArray*)itemLayoutAttributes withBounds:(CGRect)bounds
{
    if ([itemLayoutAttributes count] == 0) {
        return nil;
    }

    NSMutableDictionary *scratchDecorationLayoutAttributes = [[NSMutableDictionary alloc] init];
    NSMutableOrderedSet *resultDecorationLayoutAttributes = [[NSMutableOrderedSet alloc] init];
    __block CGFloat maximumRowHeight = 0;
    __block NSUInteger decorationCount = 0;
    [itemLayoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *itemLayoutAttribute, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *nextLayoutAttributes = nil;
        BOOL isLastItemInRow = NO;

        if (idx < ([itemLayoutAttributes count] - 1)) {
            nextLayoutAttributes = itemLayoutAttributes[idx + 1];

            if (CGRectGetMinY(itemLayoutAttribute.frame) != CGRectGetMinY(nextLayoutAttributes.frame)) {
                // If the Y origin of the frames differ, then we have reached the end of the
                // current row.
                nextLayoutAttributes = nil;
                isLastItemInRow = YES;
            }
        } else {
            isLastItemInRow = YES;
        }

        // Don't update the height if the current layout attribute is the featured item.
        // This item's height is equal to several rows and will skew the height heuristics
        if (itemLayoutAttribute.representedElementCategory == UICollectionElementCategoryCell) {
            if (!self.isFeatured || !(itemLayoutAttribute.indexPath.item == 0)) {
                CGFloat itemHeight = CGRectGetHeight(itemLayoutAttribute.frame);
                if (maximumRowHeight < itemHeight) {
                    maximumRowHeight = itemHeight;
                }
            }
        }

        if (!isLastItemInRow) {
            const CGFloat decorationOriginX = floor(CGRectGetMaxX(itemLayoutAttribute.frame));
            if (!scratchDecorationLayoutAttributes[@(decorationOriginX)]) {
                const CGFloat decorationOriginY = ceil(CGRectGetMinY(itemLayoutAttribute.frame));
                const CGFloat decorationWidth = ceil(CGRectGetMinX(nextLayoutAttributes.frame) - decorationOriginX);

                NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:self.section];
                indexPath = [indexPath indexPathByAddingIndex:decorationCount];

                UICollectionViewLayoutAttributes *decorationLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:MITNewsReusableViewIdentifierDivider withIndexPath:indexPath];

                decorationLayoutAttributes.zIndex = 2048;
                decorationLayoutAttributes.frame = CGRectMake(decorationOriginX, decorationOriginY, decorationWidth, 0);

                scratchDecorationLayoutAttributes[@(decorationOriginX)] = decorationLayoutAttributes;
                decorationCount += 1;
            }
        } else {
            [scratchDecorationLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSNumber *decorationKey, UICollectionViewLayoutAttributes *decorationLayoutAttributes, BOOL *stop) {
                if (CGRectGetHeight(decorationLayoutAttributes.frame) == 0) {
                    CGRect frame = decorationLayoutAttributes.frame;
                    frame.size.height = maximumRowHeight;
                    decorationLayoutAttributes.frame = frame;
                }
            }];

            [resultDecorationLayoutAttributes addObjectsFromArray:[scratchDecorationLayoutAttributes allValues]];

            if (self.isFeatured) {
                [scratchDecorationLayoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSNumber *decorationKey, UICollectionViewLayoutAttributes *decorationLayoutAttributes, BOOL *stop) {
                    const CGFloat decorationOriginX = [decorationKey doubleValue];
                    const CGFloat decorationMaxY = CGRectGetMaxY(decorationLayoutAttributes.frame);
                    const CGFloat itemOriginY = CGRectGetMinY(itemLayoutAttribute.frame);
                    const CGFloat itemOriginX = CGRectGetMinX(itemLayoutAttribute.frame);

                    if (decorationOriginX < itemOriginX) {
                        if (decorationMaxY < itemOriginY) {
                            CGFloat offset = itemOriginY - CGRectGetMaxY(decorationLayoutAttributes.frame);

                            CGRect frame = decorationLayoutAttributes.frame;
                            frame.size.height += offset + maximumRowHeight;
                            decorationLayoutAttributes.frame = frame;
                        }
                    }
                 }];
            } else {
                [scratchDecorationLayoutAttributes removeAllObjects];
            }

            maximumRowHeight = 0;
        }
    }];

    return [resultDecorationLayoutAttributes array];
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
