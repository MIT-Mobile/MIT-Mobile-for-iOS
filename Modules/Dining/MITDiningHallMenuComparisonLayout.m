#import <UIKit/UIKit.h>
#import "MITDiningHallMenuComparisonLayout.h"

@interface SectionDividerView : UICollectionReusableView
@end

@implementation SectionDividerView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    }
    return self;
}
@end

NSString * const MITDiningMenuComparisonCellKind = @"DiningMenuCell";
NSString * const MITDiningMenuComparisonSectionHeaderKind = @"DiningMenuSectionHeader";
NSString * const MITDiningMenuComparisonSectionDividerKind = @"DiningMenuSectionDivider";

@interface MITDiningHallMenuComparisonLayout ()

@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) CGSize itemSize;
@property (nonatomic) CGFloat interItemSpacingY;
@property (nonatomic) NSInteger numberOfColumns;
@property (nonatomic) CGFloat heightOfSectionHeader;

@property (nonatomic, strong) NSDictionary *layoutInfo;

@end

@implementation MITDiningHallMenuComparisonLayout

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

- (void) setup
{
    // layout some default values
    self.itemInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    self.itemSize = CGSizeMake(60, 40);
    self.interItemSpacingY = 5;
    self.numberOfColumns = 5;
    self.heightOfSectionHeader = 48;
    
    [self registerClass:[SectionDividerView class] forDecorationViewOfKind:MITDiningMenuComparisonSectionDividerKind];
    
}

- (id<CollectionViewDelegateMenuCompareLayout>) layoutDelegate
{
    // Helper method to get delegate
    return (id<CollectionViewDelegateMenuCompareLayout>)self.collectionView.delegate;
}

- (void) prepareLayout
{
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *headerLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *dividerLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath;
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemCount; item++) {
            indexPath = [NSIndexPath indexPathForRow:item inSection:section];
            
            // Menu Item Cells
            UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForMenuItemAtIndexPath:indexPath inLayoutSet:newLayoutInfo];
            cellLayoutInfo[indexPath] = itemAttributes;
            newLayoutInfo[MITDiningMenuComparisonCellKind] = cellLayoutInfo;
            
            if (indexPath.row == 0) {
                // only need to do these once per section
                // Section Header
                UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:MITDiningMenuComparisonSectionHeaderKind withIndexPath:indexPath];
                headerAttributes.frame = [self frameForHeaderAtIndexPath:indexPath];
                headerLayoutInfo[indexPath] = headerAttributes;
                newLayoutInfo[MITDiningMenuComparisonSectionHeaderKind] = headerLayoutInfo;
                
                // Section Dividers
                UICollectionViewLayoutAttributes *dividerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:MITDiningMenuComparisonSectionDividerKind withIndexPath:indexPath];
                dividerAttributes.frame = [self frameForDividerAtIndexPath:indexPath];
                dividerLayoutInfo[indexPath] = dividerAttributes;

                if (indexPath.section == sectionCount - 1) {
                    // need to add section divider at right edge of collectionview
                    indexPath = [NSIndexPath indexPathForRow:item inSection:section];
                    UICollectionViewLayoutAttributes *dividerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:MITDiningMenuComparisonSectionDividerKind withIndexPath:indexPath];
                    dividerAttributes.frame = [self frameForDividerAtIndexPath:indexPath];
                    dividerLayoutInfo[indexPath] = dividerAttributes;
                }
                
                newLayoutInfo[MITDiningMenuComparisonSectionDividerKind] = dividerLayoutInfo;
            }
        }
    }
    
    self.layoutInfo = newLayoutInfo;
}

- (CGRect) frameForMenuItemAtIndexPath:(NSIndexPath *)indexPath inLayoutSet:(NSDictionary *)layoutDictionary
{

    CGFloat itemHeight = [[self layoutDelegate] collectionView:self.collectionView layout:self heightForItemAtIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        // first item in section. should be placed at top, just under sectionHeader
        return CGRectMake(self.columnWidth * indexPath.section, self.heightOfSectionHeader, self.columnWidth, itemHeight);
    } else {
        // not first item in section. need to look back and place directly below previous frame
        NSDictionary *cellLayoutInfo = layoutDictionary[MITDiningMenuComparisonCellKind];
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:indexPath.row - 1 inSection:indexPath.section];
        UICollectionViewLayoutAttributes *previousItemAttributes = cellLayoutInfo[previousIndexPath];
        CGRect previousFrame = previousItemAttributes.frame;
        
        return CGRectMake(previousFrame.origin.x, previousFrame.origin.y + previousFrame.size.height, self.columnWidth, itemHeight);
    }
    
    return CGRectZero;
}

- (CGRect) frameForHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    CGPoint contentOffset = self.collectionView.contentOffset;
    CGRect frame = CGRectMake(self.columnWidth * indexPath.section, MAX(contentOffset.y, 0), self.columnWidth, self.heightOfSectionHeader);
    return frame;
}

- (CGRect) frameForDividerAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat dividerWidth = 1;
    CGFloat x = (indexPath.section * self.columnWidth);
    CGPoint contentOffset = self.collectionView.contentOffset;
    return CGRectMake(x, MAX(contentOffset.y, 0), dividerWidth, CGRectGetHeight(self.collectionView.bounds));
}

- (NSArray *) layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementsIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *innerstop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                if ([attributes.representedElementKind isEqualToString:MITDiningMenuComparisonSectionHeaderKind]) {
                    attributes.frame = [self frameForHeaderAtIndexPath:indexPath];
                    attributes.zIndex = 1000;
                } else if ([attributes.representedElementKind isEqualToString:MITDiningMenuComparisonSectionDividerKind]) {
                    attributes.frame = [self frameForDividerAtIndexPath:indexPath];
                    attributes.zIndex = 1024;
                }
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[MITDiningMenuComparisonCellKind][indexPath];
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[MITDiningMenuComparisonSectionHeaderKind][indexPath];
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForDecorationViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutInfo[MITDiningMenuComparisonSectionDividerKind][indexPath];
}

- (CGSize) collectionViewContentSize
{
    __block CGFloat height = 0;
    __block CGFloat width = 0;
    
    // get max Y for the tallest column. return collectionView width and calculated height
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementsIdentifier, NSDictionary *elementsInfo, BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *innerstop) {
            if (![attributes.representedElementKind isEqualToString:MITDiningMenuComparisonSectionDividerKind]) {                 
                // don't take the SectionDividers into account, except for width of final divider
                UICollectionViewLayoutAttributes *divattr = [self layoutAttributesForDecorationViewOfKind:MITDiningMenuComparisonSectionDividerKind atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                CGFloat dividerWidth = divattr.frame.size.width;
                
                CGFloat tempHeight = CGRectGetMaxY(attributes.frame);
                CGFloat tempWidth = CGRectGetMaxX(attributes.frame) + dividerWidth;
                height = (tempHeight > height) ? tempHeight : height;   // if tempHeight is greater update height
                width = (tempWidth > width) ? tempWidth : width;        // if tempWidth is greater update width
            }
        }];
    }];
    
    return CGSizeMake(width, height);
}

@end
