//
//  DiningHallMenuCompareLayout.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/22/13.
//
//

#import "DiningHallMenuCompareLayout.h"
#import "PSTCollectionView.h"

static NSString * const MITDiningMenuCompareCellKind = @"DiningMenuCell";

@interface DiningHallMenuCompareLayout ()

@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) CGSize itemSize;
@property (nonatomic) CGFloat interItemSpacingY;
@property (nonatomic) NSInteger numberOfColumns;

@property (nonatomic, strong) NSDictionary *layoutInfo;

@end

@implementation DiningHallMenuCompareLayout

- (void) setup
{
    // layout some default values
    self.itemInsets = UIEdgeInsetsMake(0, 1, 0, 1);
    self.itemSize = CGSizeMake(60, 40);
    self.interItemSpacingY = 5;
    self.numberOfColumns = 5;
}

- (id) init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void) prepareLayout
{
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemCount; item++) {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            PSTCollectionViewLayoutAttributes *itemAttributes = [PSTCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForMenuItemAtIndexPath:indexPath inLayoutSet:newLayoutInfo];
            
            cellLayoutInfo[indexPath] = itemAttributes;
            newLayoutInfo[MITDiningMenuCompareCellKind] = cellLayoutInfo;
        }
    }
    
    self.layoutInfo = newLayoutInfo;
}

- (CGRect) frameForMenuItemAtIndexPath:(NSIndexPath *)indexPath inLayoutSet:(NSDictionary *)layoutDictionary
{
//    CGFloat itemHeight;
//    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:heightForItemAtIndexPath:)]) {
//        itemHeight = [self.collectionView.delegate collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath];
//    }
    id delegate = (id<CollectionViewDelegateMenuCompareLayout>)self.collectionView.delegate;
    CGFloat itemHeight = [delegate collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        // first item in section. should be placed at top
        return CGRectMake(self.columnWidth * indexPath.section, 0, self.columnWidth, itemHeight);
    } else {
        // not first item in section. need to look back and place directly below previous frame
        NSDictionary *cellLayoutInfo = layoutDictionary[MITDiningMenuCompareCellKind];
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.row - 1 inSection:indexPath.section];
        PSTCollectionViewLayoutAttributes *previousItemAttributes = cellLayoutInfo[previousIndexPath];
        CGRect previousFrame = previousItemAttributes.frame;
        
        return CGRectMake(previousFrame.origin.x, previousFrame.origin.y + previousFrame.size.height, self.columnWidth, itemHeight);
    }
    
    return CGRectZero;
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementsIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, PSTCollectionViewLayoutAttributes *attributes, BOOL *innerstop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    return allAttributes;
}

- (PSTCollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[MITDiningMenuCompareCellKind][indexPath];
}

- (CGSize) collectionViewContentSize
{
    __block CGFloat height = 0;
    
    // get max Y for the tallest column. return collectionView width and calculated height
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementsIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, PSTCollectionViewLayoutAttributes *attributes, BOOL *innerstop) {
            CGFloat tempHeight = CGRectGetMaxY(attributes.frame);
            if (tempHeight > height) {
                height = tempHeight;
            }
        }];
    }];
    
    return CGSizeMake(CGRectGetWidth(self.collectionView.bounds), height);
}




@end
