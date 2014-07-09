#import <UIKit/UIKit.h>

@protocol MITCollectionViewDelegateNewsGrid;

@interface MITCollectionViewNewsGridLayout : UICollectionViewLayout
@property (nonatomic,readonly,weak) id<MITCollectionViewDelegateNewsGrid> collectionViewDelegate;

// Set these if you aren't using the associated delegate methods
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) CGFloat headerHeight;

@property (nonatomic) CGFloat minimumInterItemPadding;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) CGFloat lineSpacing;

- (instancetype)init;

- (NSUInteger)numberOfColumnsInSection:(NSInteger)section;
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (NSUInteger)featuredStoryHorizontalSpanInSection:(NSInteger)section;
- (NSUInteger)featuredStoryVerticalSpanInSection:(NSInteger)section;
@end


@protocol MITCollectionViewDelegateNewsGrid <UICollectionViewDelegate>
@optional
- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout numberOfColumnsInSection:(NSInteger)section;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForHeaderInSection:(NSInteger)section;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryVerticalSpanInSection:(NSInteger)section;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryHorizontalSpanInSection:(NSInteger)section;
@end