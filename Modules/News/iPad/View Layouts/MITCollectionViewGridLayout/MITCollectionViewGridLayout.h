#import <UIKit/UIKit.h>

@protocol MITCollectionViewDelegateNewsGrid;

@interface MITCollectionViewGridLayout : UICollectionViewLayout
@property (nonatomic,readonly,weak) id<MITCollectionViewDelegateNewsGrid> collectionViewDelegate;

// Set these if you aren't using the associated delegate methods
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) CGFloat headerHeight;

@property (nonatomic) CGFloat minimumInterItemPadding;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) CGFloat lineSpacing;

@property (nonatomic,readonly) CGFloat columnWidth;
@property (nonatomic,readonly) CGFloat interItemPadding;


- (instancetype)init;

- (NSUInteger)numberOfColumnsInSection:(NSInteger)section;
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (NSUInteger)featuredStoryHorizontalSpanInSection:(NSInteger)section;
- (NSUInteger)featuredStoryVerticalSpanInSection:(NSInteger)section;
@end


@protocol MITCollectionViewDelegateNewsGrid <UICollectionViewDelegate>
@optional
- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout numberOfColumnsInSection:(NSInteger)section;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath withWidth:(CGFloat)width;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForHeaderInSection:(NSInteger)section withWidth:(CGFloat)width;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout featuredStoryVerticalSpanInSection:(NSInteger)section;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout featuredStoryHorizontalSpanInSection:(NSInteger)section;
@end