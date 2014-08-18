#import "MITNewsCategoryGridViewController.h"
#import "MITNewsiPadViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStory.h"
#import "MITNewsConstants.h"
#import "MITNewsSearchController.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsLoadMoreCollectionViewCell.h"
#import "MITCollectionViewGridLayout.h"

@interface MITNewsCategoryGridViewController()
@property (nonatomic, strong) NSString *errorMessage;
@end

@implementation MITNewsCategoryGridViewController {
    BOOL _storyUpdateInProgress;
    BOOL _storyUpdateFailed;
}

- (NSString*)identifierForCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self numberOfStoriesForCategoryInSection:indexPath.section] - 1 == indexPath.row && [self.dataSource canLoadMoreItemsForCategoryInSection:indexPath.section]) {
        return MITNewsCellIdentifierStoryLoadMore;
    } else {
        return [super identifierForCellAtIndexPath:indexPath];
    }
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
            MITNewsLoadMoreCollectionViewCell *loadMoreCell = (MITNewsLoadMoreCollectionViewCell*)cell;

            if(_storyUpdateFailed) {
                loadMoreCell.textLabel.text = self.errorMessage;
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

- (void)getMoreStoriesForSection:(NSInteger *)section
{
    if(!_storyUpdateInProgress && !_storyUpdateFailed) {
        _storyUpdateInProgress = YES;
        
        [self.delegate getMoreStoriesForSection:section completion:^(NSError * error) {
            _storyUpdateInProgress = FALSE;
            if (error) {
                self.errorMessage = error.localizedDescription;
                _storyUpdateFailed = TRUE;
                if (self.navigationController.toolbarHidden) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSTimer scheduledTimerWithTimeInterval:2
                                                         target:self
                                                       selector:@selector(clearFailAfterTwoSeconds)
                                                       userInfo:nil
                                                        repeats:NO];
                    });
                }
                [self reloadItemAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] - 1 inSection:0]];
            }
        }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    NSUInteger item = [self numberOfStoriesForCategoryInSection:0] - 1;
    NSIndexPath *loadMoreIndexPath = [NSIndexPath indexPathForItem:item inSection:0];

    _storyUpdateFailed = FALSE;
    [self reloadItemAtIndexPath:loadMoreIndexPath];
}

- (void)reloadItemAtIndexPath:(NSIndexPath *)indexPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    });
}

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

@end
