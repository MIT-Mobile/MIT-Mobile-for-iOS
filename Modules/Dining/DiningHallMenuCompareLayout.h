#import <UIKit/UIKit.h>

extern NSString * const MITDiningMenuComparisonCellKind;
extern NSString * const MITDiningMenuComparisonSectionHeaderKind;

@protocol CollectionViewDelegateMenuCompareLayout <UICollectionViewDelegate>
@required
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath;
@optional

@end

@interface DiningHallMenuCompareLayout : UICollectionViewLayout

@property (nonatomic, assign) CGFloat columnWidth;
//@property (nonatomic, assign) id<CollectionViewDelegateMenuCompareLayout> delegate;

@end
