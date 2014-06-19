#import "MITCollectionViewGridLayoutSection.h"
#import "MITCollectionViewNewsGridLayout.h"
#import "MITCollectionViewGridLayoutRow.h"

@interface MITCollectionViewGridLayoutSection ()
@property (nonatomic,readwrite) NSInteger section;

@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) NSUInteger numberOfColumns;

- (instancetype)initWithLayout:(MITCollectionViewNewsGridLayout*)layout;
@end

@implementation MITCollectionViewGridLayoutSection {
    NSMutableArray *_itemLayoutAttributes;
    BOOL _needsLayout;
}

@synthesize headerLayoutAttributes = _headerLayoutAttributes;
@synthesize featuredItemLayoutAttributes = _featuredItemLayoutAttributes;

+ (instancetype)sectionWithLayout:(MITCollectionViewNewsGridLayout*)layout section:(NSInteger)section numberOfColumns:(NSInteger)numberOfColumns
{
    MITCollectionViewGridLayoutSection *sectionLayout = [[self alloc] initWithLayout:layout];
    sectionLayout.section = section;
    sectionLayout.numberOfColumns = numberOfColumns;

    return sectionLayout;
}

- (instancetype)initWithLayout:(MITCollectionViewNewsGridLayout*)layout
{
    self = [super init];
    if (self) {
        _layout = layout;
        _numberOfColumns = 2;
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
    
    return _featuredItemLayoutAttributes;
}

- (UICollectionViewLayoutAttributes*)headerLayoutAttributes
{
    [self layoutIfNeeded];
    
    
    return _headerLayoutAttributes;
}

- (NSArray*)itemLayoutAttributes
{
    [self layoutIfNeeded];
    return [_itemLayoutAttributes copy];
}

- (CGFloat)contentWidth
{
    return CGRectGetWidth(self.layout.collectionView.bounds);
}

- (CGRect)frame
{
    return CGRectOffset(self.bounds, self.origin.x, self.origin.y);
}

- (void)invalidateLayout
{
    _featuredItemLayoutAttributes = nil;
    _headerLayoutAttributes = nil;
    _itemLayoutAttributes = nil;
    _needsLayout = YES;
}

- (void)layoutIfNeeded
{
    if (_needsLayout) {
        // When performing the layout, assume we have an infinite vertical canvas to work with.
        // Once everything is layed out, we'll go back and give the height a correct value
        CGRect layoutBounds = CGRectMake(0, 0, [self contentWidth], CGFLOAT_MAX);
        
        const CGFloat numberOfItems = [self.layout.collectionView numberOfItemsInSection:self.section];
        if (numberOfItems == 0) {
            return;
        }

        const NSInteger numberOfColumns = self.numberOfColumns;
        
        // Make sure that there is enough padding between successive
        const CGFloat minimumInterItemPadding = 2 * floor(self.layout.minimumInterItemPadding / 2.0) + 1;
        const CGFloat columnWidth = floor((CGRectGetWidth(layoutBounds) / numberOfColumns) - (minimumInterItemPadding * (numberOfColumns - 1)));
        
        
        UICollectionViewLayoutAttributes *headerLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:@"Header" withIndexPath:[NSIndexPath indexPathWithIndex:self.section]];
        
        CGRect headerFrame = CGRectZero;
        CGFloat headerHeight = [self.layout heightForHeaderInSection:self.section];
        CGRectDivide(layoutBounds, &headerFrame, &layoutBounds, headerHeight, CGRectMinYEdge);
        headerLayoutAttributes.frame = headerFrame;
        _headerLayoutAttributes = headerLayoutAttributes;
        
        
        const BOOL hasFeaturedItem = [self.layout showFeaturedItemInSection:self.section];
        NSUInteger featuredStoryColumnSpan = 0;
        NSUInteger featuredStoryRowSpan = 0;
        if (hasFeaturedItem) {
            featuredStoryColumnSpan = [self.layout featuredStoryHorizontalSpanInSection:self.section];
            featuredStoryRowSpan = [self.layout featuredStoryVerticalSpanInSection:self.section];
            
            NSAssert(featuredStoryColumnSpan < self.numberOfColumns, @"there must be space for at least 1 item after the featured story", self.numberOfColumns);
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

            if (![currentLayoutRow canAcceptItems]) {
                if (currentLayoutRow) {
                    [rowLayouts addObject:currentLayoutRow];
                }
                
                NSUInteger numberOfItemsInRow = numberOfColumns;
                
                // If the row we are laying out overlaps the featured story, make sure to reduce the number
                // of items it is capable of holding
                if (numberOfRows() < featuredStoryRowSpan) {
                    numberOfItemsInRow -= featuredStoryColumnSpan;
                }
                
                currentLayoutRow = [MITCollectionViewGridLayoutRow rowWithMaximumNumberOfItems:numberOfItemsInRow interItemSpacing:minimumInterItemPadding];
            }
            
            CGSize itemSize = CGSizeMake(columnWidth, [self.layout heightForItemAtIndexPath:indexPath]);
            [currentLayoutRow addItemForIndexPath:indexPath itemSize:itemSize];
        }
        
        
        // Now that each row has been partitioned and sized, place the
        // featured item and create its frame.
        UICollectionViewLayoutAttributes *featuredItemLayoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.section]];
        
        CGFloat featuredItemHeight = 0;
        NSIndexSet *indentedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, featuredStoryRowSpan)];
        [rowLayouts enumerateObjectsAtIndexes:indentedRowIndexes options:0 usingBlock:^(MITCollectionViewGridLayoutRow *rowLayout, NSUInteger idx, BOOL *stop) {
            featuredItemHeight += rowLayout.contentSize.height;
        }];
        
        CGRect featuredItemFrame = CGRectZero;
        CGRect scratchFrame = CGRectZero;
        CGRectDivide(layoutBounds, &featuredItemFrame, &scratchFrame, featuredItemHeight, CGRectMinYEdge);
        
        CGFloat featuredItemWidth = (columnWidth * featuredStoryColumnSpan) + (minimumInterItemPadding * (featuredStoryColumnSpan - 1));
        CGRectDivide(featuredItemFrame, &featuredItemFrame, &scratchFrame, featuredItemWidth, CGRectMinXEdge);
        
        featuredItemLayoutAttributes.frame = featuredItemFrame;
        _featuredItemLayoutAttributes = featuredItemLayoutAttributes;


        // At this point, the featured item and the header are layed out properly
        // but the rows are bunched up at the top (but sized correctly!). Run through
        // each of the rows here and shift the origins to where they need to be
        NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
        __block CGPoint origin = layoutBounds.origin;
        [rowLayouts enumerateObjectsUsingBlock:^(MITCollectionViewGridLayoutRow *row, NSUInteger rowIndex, BOOL *stop) {
            CGRect rowFrame = CGRectZero;
            CGRectDivide(layoutBounds, &rowFrame, &layoutBounds, row.contentSize.height, CGRectMinYEdge);
            
            CGRect scratchFrame = CGRectZero;
            if (rowIndex < featuredStoryRowSpan) {
                CGRectDivide(layoutBounds, &scratchFrame, &rowFrame, featuredItemWidth + minimumInterItemPadding, CGRectMinXEdge);
            }
            
            row.origin = rowFrame.origin;
            [layoutAttributes addObjectsFromArray:[row itemLayoutAttributes]];
            [layoutAttributes addObjectsFromArray:[row decorationLayoutAttributes]];
            
            // If we are on either the 1st or (n-2) row, shift the layout bounds down
            // a bit further to account for the interLineSpacing
            NSRange spacingIndexRange = NSMakeRange(1, numberOfRows() - 2);
            NSIndexSet *spacingIndexes = [NSIndexSet indexSetWithIndexesInRange:spacingIndexRange];
            if ([spacingIndexes containsIndex:rowIndex]) {
                CGRect scratchSliceRect = CGRectZero;
                CGRectDivide(layoutBounds, &scratchSliceRect, &layoutBounds, self.layout.interLineSpacing, CGRectMinXEdge);
            }
        }];
        
        MITCollectionViewGridLayoutRow *lastRowLayout = [rowLayouts lastObject];
        layoutBounds.size.height = CGRectGetMaxX(lastRowLayout.contentFrame);
        
        _itemLayoutAttributes = layoutAttributes;
        
        _needsLayout = NO;
    }
}

@end
