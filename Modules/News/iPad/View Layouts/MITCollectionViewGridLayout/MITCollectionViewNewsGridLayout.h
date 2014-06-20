#import <UIKit/UIKit.h>

@protocol MITCollectionViewDelegateNewsGrid;

@interface MITCollectionViewNewsGridLayout : UICollectionViewLayout
@property (nonatomic,readonly,weak) id<MITCollectionViewDelegateNewsGrid> collectionViewDelegate;

// Set these if you aren't using the associated delegate methods
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) CGFloat headerHeight;

//
@property (nonatomic) CGFloat minimumInterItemPadding;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) CGFloat sectionSpacing;

- (instancetype)init;

- (NSUInteger)numberOfColumnsInSection:(NSInteger)section;
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (BOOL)showFeaturedItemInSection:(NSInteger)section;
- (NSUInteger)featuredStoryHorizontalSpanInSection:(NSInteger)section;
- (NSUInteger)featuredStoryVerticalSpanInSection:(NSInteger)section;
@end



@protocol MITCollectionViewDelegateNewsGrid <UICollectionViewDelegate>
@optional
- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout numberOfColumnsInSection:(NSInteger)section;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForHeaderInSection:(NSInteger)section;

- (BOOL)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout showFeaturedItemInSection:(NSInteger)section;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryVerticalSpanInSection:(NSInteger)section;

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryHorizontalSpanInSection:(NSInteger)section;
@end