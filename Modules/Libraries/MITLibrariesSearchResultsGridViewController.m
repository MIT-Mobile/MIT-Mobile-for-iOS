#import "MITLibrariesSearchResultsGridViewController.h"
#import "MITLibrariesSearchController.h"
#import "MITLibrariesWorldcatItemCollectionCell.h"
#import "SVPullToRefresh.h"
#import "TopAlignedStickyHeaderCollectionViewFlowLayout.h"

static NSString * const kWorldcatItemCollectionCellIdentifier = @"kWorldcatItemCollectionCellIdentifier";
static CGFloat const kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding = 20.0;

@interface MITLibrariesSearchResultsGridViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;

@end

@implementation MITLibrariesSearchResultsGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MITLibrariesWorldcatItemCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:kWorldcatItemCollectionCellIdentifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.collectionViewLayout = [[TopAlignedStickyHeaderCollectionViewFlowLayout alloc] init];
    
    self.collectionView.showsInfiniteScrolling = NO;
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        NSInteger startingResultCount = self.searchController.results.count;
        
        [self.searchController getNextResults:^(NSError *error) {
            [self.collectionView.infiniteScrollingView stopAnimating];
            if (error) {
                self.collectionView.showsInfiniteScrolling = NO;
            } else {
                NSInteger addedResultCount = self.searchController.results.count - startingResultCount;
                NSMutableArray *newIndexPaths = [NSMutableArray arrayWithCapacity:addedResultCount];
                for (NSInteger i = 0; i < addedResultCount; i++) {
                    [newIndexPaths addObject:[NSIndexPath indexPathForRow:(startingResultCount + i) inSection:0]];
                }
                
                [self.collectionView insertItemsAtIndexPaths:newIndexPaths];
                
                self.collectionView.showsInfiniteScrolling = self.searchController.hasMoreResults;
            }
        }];
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.collectionView reloadData];
}

- (void)reloadResultsView
{
    [self.collectionView reloadData];
    self.collectionView.showsInfiniteScrolling = self.searchController.hasMoreResults;
}

- (void)showLoadingView
{
    self.messageLabel.text = @"Loading...";
    self.collectionView.hidden = YES;
    self.messageLabel.hidden = NO;
    self.collectionView.contentOffset = CGPointMake(0, 0);
}

- (void)showErrorView
{
    self.messageLabel.text = @"There was an error loading your search.";
    self.collectionView.hidden = YES;
    self.messageLabel.hidden = NO;
}

- (void)showNoResultsView
{
    self.messageLabel.text = @"No results found.";
    self.collectionView.hidden = YES;
    self.messageLabel.hidden = NO;
}

- (void)showResultsView
{
    self.messageLabel.hidden = YES;
    self.collectionView.hidden = NO;
}

#pragma mark - UICollectionView methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.searchController.results.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesWorldcatItemCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kWorldcatItemCollectionCellIdentifier forIndexPath:indexPath];
    [cell setContent:self.searchController.results[indexPath.row]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat interItemSpacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    CGFloat cellWidth = 0;
    NSInteger numberOfColumns = 0;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        numberOfColumns = 2;
    } else {
        numberOfColumns = 3;
    }
    
    cellWidth = (collectionView.bounds.size.width - (2 * kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding) - ((numberOfColumns - 1) * interItemSpacing)) / numberOfColumns;
    NSLog(@"cell width: %f", cellWidth);
    CGFloat cellHeight = [MITLibrariesWorldcatItemCollectionCell heightForContent:self.searchController.results[indexPath.row] width:cellWidth];
    
    return CGSizeMake(floor(cellWidth), cellHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding, 10, kMITLibrariesSearchGridCollectionViewSectionHorizontalPadding);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(librariesSearchResultsViewController:didSelectItem:)]) {
        MITLibrariesWorldcatItem *item = self.searchController.results[indexPath.row];
        [self.delegate librariesSearchResultsViewController:self didSelectItem:item];
    }
}

@end
