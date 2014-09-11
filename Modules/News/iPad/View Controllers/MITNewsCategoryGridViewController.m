#import "MITNewsCategoryGridViewController.h"
#import "MITNewsiPadViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStory.h"
#import "MITNewsConstants.h"
#import "MITNewsSearchController.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsLoadMoreCollectionViewCell.h"
#import "MITCollectionViewGridLayout.h"
#import "MITNewsDataSource.h"
#import "MITNewsiPadCategoryViewController.h"

@interface MITNewsCategoryGridViewController()
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic) BOOL storyUpdateInProgress;
@end

@implementation MITNewsCategoryGridViewController
@synthesize storyUpdateInProgress = _storyUpdateInProgress;

#pragma mark UICollectionViewDataSource
- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    NSUInteger numberOfStories = [super numberOfStoriesForCategoryInSection:section];
    
    if ([self.dataSource canLoadMoreItemsForCategoryInSection:section]) {
        return numberOfStories + 1;
    } else {
        return numberOfStories;
    }
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForHeaderInSection:(NSInteger)section withWidth:(CGFloat)width;
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(MITCollectionViewGridLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath withWidth:(CGFloat)width
{
    NSString *identifier = [self identifierForCellAtIndexPath:indexPath];

    if ([identifier isEqualToString:MITNewsCellIdentifierStoryLoadMore]) {
        return 175.;
    } else {
        return [super collectionView:collectionView layout:layout heightForItemAtIndexPath:indexPath withWidth:width];
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    if ([cell.reuseIdentifier isEqualToString:MITNewsCellIdentifierStoryLoadMore]) {
        if ([cell isKindOfClass:[MITNewsLoadMoreCollectionViewCell class]]) {
            MITNewsLoadMoreCollectionViewCell *loadMoreCell = (MITNewsLoadMoreCollectionViewCell*)cell;;
            
            if(self.errorMessage) {
                loadMoreCell.textLabel.text = self.errorMessage;
                self.errorMessage = nil;
                loadMoreCell.loadingIndicator.hidden = YES;
            } else if (_storyUpdateInProgress) {
                loadMoreCell.textLabel.text = @"Loading More...";
                loadMoreCell.loadingIndicator.hidden = NO;
            } else {
                loadMoreCell.textLabel.text = @"Load More...";
                loadMoreCell.loadingIndicator.hidden = YES;
            }

            return loadMoreCell;
        } else {
            DDLogWarn(@"cell at %@ with identifier %@ expected a cell of type %@, got %@",indexPath,cell.reuseIdentifier,NSStringFromClass([MITNewsLoadMoreCollectionViewCell class]),NSStringFromClass([cell class]));

            return cell;
        }
    }
    return cell;
}

- (NSString*)identifierForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self numberOfStoriesForCategoryInSection:indexPath.section] - 1 == indexPath.row && [self.dataSource canLoadMoreItemsForCategoryInSection:indexPath.section]) {
        return MITNewsCellIdentifierStoryLoadMore;
    } else {
        return [super identifierForCellAtIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self identifierForCellAtIndexPath:indexPath];

    if ([identifier isEqualToString:MITNewsCellIdentifierStoryLoadMore]) {
        BOOL canLoadMoreItems = [self.dataSource canLoadMoreItemsForCategoryInSection:indexPath.section];
        if (canLoadMoreItems && !_storyUpdateInProgress) {
            [self getMoreStoriesForSection:indexPath.section];
        }
    } else {
        [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark More Stories
- (void)getMoreStoriesForSection:(NSInteger)section
{
    if(!_storyUpdateInProgress && !self.errorMessage) {
        [self.delegate getMoreStoriesForSection:section completion:^(NSError * error) {
        }];
    }
}

#pragma mark Reload Cell
- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
}

- (void)setError:(NSString *)errorMessage
{
    self.errorMessage = errorMessage;
}

- (void)setProgress:(BOOL)progress
{
    self.storyUpdateInProgress = progress;
}
@end
