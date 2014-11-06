#import "MITToursStopInfiniteScrollCollectionViewManager.h"

@implementation MITToursStopInfiniteScrollCollectionViewManager

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Present three copies of each item, so that we have some padding for the infinite scroll
    return self.stops.count * 3;
}

- (MITToursStop *)stopForIndexPath:(NSIndexPath *)path
{
    NSInteger index = path.item % self.stops.count;
    return [self.stops objectAtIndex:index];
}

@end
