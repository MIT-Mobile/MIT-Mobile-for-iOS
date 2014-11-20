#import "MITToursStopInfiniteScrollCollectionViewManager.h"

@implementation MITToursStopInfiniteScrollCollectionViewManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentMultiple = 5;
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Present three copies of each item, so that we have some padding for the infinite scroll
    return [super collectionView:collectionView numberOfItemsInSection:section] * self.contentMultiple;
}

- (MITToursStop *)stopForIndexPath:(NSIndexPath *)path
{
    NSArray *stops = self.stopsInDisplayOrder;
    if (!stops) {
        stops = self.stops;
    }
    NSInteger index = path.item % stops.count;
    return [stops objectAtIndex:index];
}

@end
