#import <UIKit/UIKit.h>

@class TopAlignedStickyHeaderCollectionViewFlowLayout;

@protocol TopAlignedStickyHeaderCollectionViewFlowLayoutDelegate <NSObject>

@required
- (void)collectionView:(UICollectionView *)collectionView headerScrolledUpToTopInSection:(NSInteger)section;
- (void)collectionView:(UICollectionView *)collectionView headerScrolledDownBelowTopInSection:(NSInteger)section;

@end

@interface TopAlignedStickyHeaderCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<TopAlignedStickyHeaderCollectionViewFlowLayoutDelegate> delegate;

@end
