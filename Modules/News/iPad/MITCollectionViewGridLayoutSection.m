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

- (NSArray*)itemLayoutAttributes
{
    if (!_itemLayoutAttributes) {
        _itemLayoutAttributes = [[NSMutableArray alloc] init];
        [self prepareLayout];
        NSAssert(_itemLayoutAttributes,@"fatal error, itemLayoutAttributes should not be nil");
    }
    
    return [_itemLayoutAttributes copy];
}

- (CGFloat)contentWidth
{
    return CGRectGetWidth(self.layout.collectionView.bounds);
}

- (CGFloat)columnWidth
{
    const CGFloat minimumInterItemPadding = self.layout.minimumInterItemPadding;
    const CGFloat contentWidth = [self contentWidth];
    const NSInteger numberOfColumns = self.numberOfColumns;

    return floor((contentWidth / numberOfColumns) - (minimumInterItemPadding * (numberOfColumns - 1)));
}

- (void)prepareLayout
{
    const CGFloat numberOfItems = [self.layout.collectionView numberOfItemsInSection:self.section];
    if (numberOfItems == 0) {
        return;
    }

    const CGFloat minimumInterItemPadding = self.layout.minimumInterItemPadding;
    const NSInteger numberOfColumns = self.numberOfColumns;
    const CGFloat columnWidth = [self columnWidth];
    const BOOL hasFeaturedItem = [self.layout showFeaturedItemInSection:self.section];

    NSUInteger featuredStoryColumnSpan = 0;
    NSUInteger featuredStoryRowSpan = 0;
    if (hasFeaturedItem) {
        featuredStoryColumnSpan = [self.layout featuredStoryHorizontalSpanInSection:self.section];
        featuredStoryRowSpan = [self.layout featuredStoryVerticalSpanInSection:self.section];
        
        NSAssert(featuredStoryColumnSpan < self.numberOfColumns, @"there must be space for at least 1 item after the featured story", self.numberOfColumns);
    }
    
    NSMutableArray *rowLayouts = [[NSMutableArray alloc] init];
    NSUInteger (^numberOfRows)(void) = ^{ return [rowLayouts count]; };
    
    // First layout pass. This allocates the items to each row,
    //  making sure to leave a space for the featured item
    //  (if present). This pass also sets the height of each row
    //  and allows us to positions each row's origin in the second pass
    MITCollectionViewGridLayoutRow *currentLayoutRow = nil;
    for (NSInteger item = 0; item < numberOfItems; ++item) {
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
            
            currentLayoutRow = [MITCollectionViewGridLayoutRow rowWithNumberOfItems:numberOfItemsInRow interItemPadding:minimumInterItemPadding];
        }
        
        CGSize itemSize = CGSizeMake(columnWidth, [self.layout heightForItemAtIndexPath:indexPath]);
        [currentLayoutRow addItemForIndexPath:indexPath itemSize:itemSize];
    }
    
    for (NSInteger item = 0; item < numberOfItems; ++item) {
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
            
            currentLayoutRow = [MITCollectionViewGridLayoutRow rowWithNumberOfItems:numberOfItemsInRow interItemPadding:minimumInterItemPadding];
        }
        
        CGSize itemSize = CGSizeMake(columnWidth, [self.layout heightForItemAtIndexPath:indexPath]);
        [currentLayoutRow addItemForIndexPath:indexPath itemSize:itemSize];
    }
    
    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    __block CGPoint origin = CGPointZero;
    [rowLayouts enumerateObjectsUsingBlock:^(MITCollectionViewGridLayoutRow *row, NSUInteger idx, BOOL *stop) {
        if (idx < featuredStoryRowSpan) {
            origin.x = (featuredStoryColumnSpan * columnWidth) + minimumInterItemPadding;
        } else {
            origin.x = 0;
        }
        
        row.origin = origin;
        [layoutAttributes addObjectsFromArray:[row layoutAttributes]];
        
        origin.y += row.contentSize.height + self.layout.interLineSpacing;
    }];
    
}

- (NSArray*)layoutAttributesForItemsUsingWidth:(CGFloat)width contentSize:(out CGSize*)outContentSize
{
    CGFloat minimumInterItemPadding = self.layout.minimumInterItemPadding;
    CGFloat columnWidth = floor((width / self.numberOfColumns) - (minimumInterItemPadding * (self.numberOfColumns - 1)));
    NSInteger numberOfItems = [self.layout.collectionView numberOfItemsInSection:self.section];

    BOOL isShowingFeaturedStory = [self.layout showFeaturedItemInSection:self.section];
    NSUInteger featuredStoryColumnSpan = 0;
    NSUInteger featuredStoryRowSpan = 0;

    if (isShowingFeaturedStory) {
        featuredStoryColumnSpan = [self.layout featuredStoryHorizontalSpanInSection:self.section];
        NSAssert(featuredStoryColumnSpan < self.numberOfColumns, @"there must be space for at least 1 item after the featured story", self.numberOfColumns);

        featuredStoryRowSpan = [self.layout featuredStoryVerticalSpanInSection:self.section];
    }

    NSMutableArray *rows = [[NSMutableArray alloc] init];


    // The initial pass is solely to populate each of the rows. Since we now
    //  how many columns and rows the featured story spans, we can arrange
    //  all of the rows so they contain the correct number of items *but*
    //  they aren't layed out until the second pass. The second pass is also
    //  where the unified content frame is calculated
    MITCollectionViewGridLayoutRow *currentRow = nil;
    for (NSInteger item = 0; item < numberOfItems; ++item) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:self.section];

        // Gets set to -1 when laying out the initial row,
        // this is then incremented up to 0 right after the new
        // row object is created
        NSInteger rowIndex = [rows count] - 1;
        if (![currentRow canAcceptItems]) {
            if (currentRow) {
                [rows addObject:currentRow];
            }

            rowIndex += 1;
            NSUInteger numberOfItems = self.numberOfColumns;

            // If the row we are laying out overlaps the featured story, make sure to reduce the number
            // of items it is capable of holding
            if (rowIndex < featuredStoryRowSpan) {
                numberOfItems -= featuredStoryColumnSpan;
            }

            currentRow = [MITCollectionViewGridLayoutRow rowWithNumberOfItems:numberOfItems interItemPadding:0.];
        }

        CGSize itemSize = CGSizeMake(columnWidth, [self.layout heightForItemAtIndexPath:indexPath]);
        [currentRow addItemForIndexPath:indexPath itemSize:itemSize];
    }


    NSMutableArray *layoutAttributes = [[NSMutableArray alloc] init];
    __block CGPoint origin = CGPointZero;
    [rows enumerateObjectsUsingBlock:^(MITCollectionViewGridLayoutRow *row, NSUInteger idx, BOOL *stop) {
        if (idx < featuredStoryRowSpan) {
            origin.x = (featuredStoryColumnSpan * columnWidth) + minimumInterItemPadding;
        } else {
            origin.x = 0;
        }

        row.origin = origin;
        [layoutAttributes addObjectsFromArray:[row layoutAttributes]];

        origin.y += row.contentSize.height + self.layout.interLineSpacing;
    }];

    return layoutAttributes;
}

@end
