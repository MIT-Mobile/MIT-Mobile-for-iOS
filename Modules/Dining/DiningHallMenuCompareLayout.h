//
//  DiningHallMenuCompareLayout.h
//  MIT Mobile
//
//  Created by Austin Emmons on 4/22/13.
//
//

#import "PSTCollectionViewLayout.h"

@protocol CollectionViewDelegateMenuCompareLayout <PSTCollectionViewDelegate>
@required
- (CGFloat)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout*)collectionViewLayout heightForItemAtIndexPath:(NSIndexPath *)indexPath;
@optional

@end

@interface DiningHallMenuCompareLayout : PSTCollectionViewLayout

@property (nonatomic, assign) CGFloat columnWidth;
//@property (nonatomic, assign) id<CollectionViewDelegateMenuCompareLayout> delegate;

@end
