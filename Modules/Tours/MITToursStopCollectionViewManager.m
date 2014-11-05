#import "MITToursStopCollectionViewManager.h"
#import "MITToursStopCollectionViewCell.h"
#import "MITToursStop.h"

@interface MITToursStopCollectionViewManager () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation MITToursStopCollectionViewManager

static NSString * const kCellReuseIdentifier = @"MITToursStopCollectionViewCell";

- (void)registerCells
{
    UINib *cellNib = [UINib nibWithNibName:@"MITToursStopCollectionViewCell" bundle:[NSBundle mainBundle]];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:kCellReuseIdentifier];
    
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast * 0.5;
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.stops.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITToursStopCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    MITToursStop *stop = [self stopForIndexPath:indexPath];
    NSURL *imageURL = [NSURL URLWithString:[stop thumbnailURL]];
    [cell configureForImageURL:imageURL title:stop.title];
    
    return cell;
}

#pragma mark - Data Source Helpers

- (MITToursStop *)stopForIndexPath:(NSIndexPath *)path
{
    return [self.stops objectAtIndex:path.item];
}

#pragma mark - UICollectionViewDelegate Methods

@end
