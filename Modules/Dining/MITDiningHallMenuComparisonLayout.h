#import <UIKit/UIKit.h>

extern NSString * const MITDiningMenuComparisonCellKind;
extern NSString * const MITDiningMenuComparisonSectionHeaderKind;

@protocol CollectionViewDelegateMenuCompareLayout <UICollectionViewDelegate>

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface MITDiningHallMenuComparisonLayout : UICollectionViewLayout

@property (nonatomic, assign) CGFloat columnWidth;

@end
