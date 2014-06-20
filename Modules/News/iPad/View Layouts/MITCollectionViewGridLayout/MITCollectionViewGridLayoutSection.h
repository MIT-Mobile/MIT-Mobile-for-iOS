#import <Foundation/Foundation.h>

@class MITCollectionViewNewsGridLayout;

@interface MITCollectionViewGridLayoutSection : NSObject
@property (nonatomic,readonly,weak) MITCollectionViewNewsGridLayout *layout;
@property (nonatomic,readonly) NSInteger section;

@property (nonatomic) UIEdgeInsets contentInsets;

@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;

@property (nonatomic,readonly,copy) UICollectionViewLayoutAttributes *headerLayoutAttributes;
@property (nonatomic,readonly,copy) UICollectionViewLayoutAttributes *featuredItemLayoutAttributes;
@property (nonatomic,readonly,copy) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly,copy) NSArray *decorationLayoutAttributes;

+ (instancetype)sectionWithLayout:(MITCollectionViewNewsGridLayout*)layout forSection:(NSInteger)section numberOfColumns:(NSInteger)numberOfColumns;

- (void)invalidateLayout;
- (NSArray*)allLayoutAttributes;
- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath;
@end
