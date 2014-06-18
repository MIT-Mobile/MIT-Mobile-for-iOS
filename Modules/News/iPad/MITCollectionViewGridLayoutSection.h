#import <Foundation/Foundation.h>

@class MITCollectionViewNewsGridLayout;

@interface MITCollectionViewGridLayoutSection : NSObject
@property (nonatomic,readonly,weak) MITCollectionViewNewsGridLayout *layout;
@property (nonatomic,readonly) NSInteger section;

@property (nonatomic) CGPoint origin;
@property (nonatomic) UIEdgeInsets contentInsets;

@property (nonatomic, readonly) CGSize bounds;
@property (nonatomic,readonly) CGRect frame;

@property (nonatomic,readonly,strong) UICollectionViewLayoutAttributes *headerLayoutAttributes;
@property (nonatomic,readonly,strong) UICollectionViewLayout *featuredItemLayoutAttributes;
@property (nonatomic,readonly,strong) NSArray *itemLayoutAttributes;

+ (instancetype)sectionWithLayout:(MITCollectionViewNewsGridLayout*)layout section:(NSInteger)section;
- (NSArray*)layoutAttributesInRect:(CGRect)rect;
- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath;

@end
