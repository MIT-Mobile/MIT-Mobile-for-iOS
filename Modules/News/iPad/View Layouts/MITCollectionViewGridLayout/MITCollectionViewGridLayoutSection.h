#import <Foundation/Foundation.h>

@class MITCollectionViewGridLayout;

typedef struct {
    NSUInteger horizontal;
    NSUInteger vertical;
} MITCollectionViewGridSpan;

extern MITCollectionViewGridSpan const MITCollectionViewGridSpanInvalid;
MITCollectionViewGridSpan MITCollectionViewGridSpanMake(NSUInteger horizontal, NSUInteger vertical);
BOOL MITCollectionViewGridSpanIsValid(MITCollectionViewGridSpan span);

@interface MITCollectionViewGridLayoutSection : NSObject
@property (nonatomic,readonly,weak) MITCollectionViewGridLayout *layout;
@property (nonatomic,readonly) NSInteger section;

@property (nonatomic) BOOL stickyHeaders;
@property (nonatomic) CGRect frame;
@property (nonatomic,readonly) CGRect bounds;

@property (nonatomic) MITCollectionViewGridSpan featuredItemSpan;
@property (nonatomic) CGFloat minimumInterItemPadding;
@property (nonatomic) CGFloat lineSpacing;

@property (nonatomic,readonly) CGFloat interItemPadding;
@property (nonatomic,readonly) CGFloat columnWidth;

@property (nonatomic,readonly,copy) UICollectionViewLayoutAttributes *headerLayoutAttributes;
@property (nonatomic,readonly,copy) UICollectionViewLayoutAttributes *featuredItemLayoutAttributes;
@property (nonatomic,readonly,copy) NSArray *itemLayoutAttributes;
@property (nonatomic,readonly,copy) NSArray *decorationLayoutAttributes;

+ (instancetype)sectionWithIndex:(NSUInteger)section layout:(MITCollectionViewGridLayout*)layout numberOfColumns:(NSInteger)numberOfColumns;

- (instancetype)initWithSection:(NSUInteger)section layout:(MITCollectionViewGridLayout*)layout;

- (void)invalidateLayout;
- (void)layoutIfNeeded;

- (NSArray*)allLayoutAttributes;
- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath;
- (UICollectionViewLayoutAttributes*)headerLayoutAttributesWithContentOffset:(CGPoint)contentOffset;
@end
