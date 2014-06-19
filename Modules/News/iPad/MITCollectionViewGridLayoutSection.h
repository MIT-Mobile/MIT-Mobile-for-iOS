#import <Foundation/Foundation.h>

@class MITCollectionViewNewsGridLayout;

@interface MITCollectionViewGridLayoutSection : NSObject
@property (nonatomic,readonly,weak) MITCollectionViewNewsGridLayout *layout;
@property (nonatomic,readonly) NSInteger section;

@property (nonatomic) CGPoint origin;
@property (nonatomic) UIEdgeInsets contentInsets;

@property (nonatomic,readonly) CGRect bounds;
@property (nonatomic,readonly) CGRect frame;

@property (nonatomic,readonly,strong) UICollectionViewLayoutAttributes *headerLayoutAttributes;
@property (nonatomic,readonly,strong) UICollectionViewLayoutAttributes *featuredItemLayoutAttributes;
@property (nonatomic,readonly,strong) NSArray *itemLayoutAttributes;

+ (instancetype)sectionWithLayout:(MITCollectionViewNewsGridLayout*)layout forSection:(NSInteger)section numberOfColumns:(NSInteger)numberOfColumns;
- (NSArray*)layoutAttributesInRect:(CGRect)rect;
- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath;

@end
