#import "MITNewsCategoryGridViewController.h"
#import "MITNewsCategoryListViewController.h"
#import "MITNewsiPadViewController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsStory.h"
#import "MITCollectionViewGridLayout.h"
#import "MITNewsConstants.h"
#import "UITableView+DynamicSizing.h"
#import "MITNewsSearchController.h"
#import "MITNewsStoryCollectionViewCell.h"

@interface MITNewsCategoryGridViewController () {
    BOOL _storyUpdateInProgress;
    BOOL _storyUpdatedFailed;
}

@end

@implementation MITNewsCategoryGridViewController

- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:numberOfStoriesForCategoryInSection:)]) {
        if([self.dataSource canLoadMoreItemsForCategoryInSection:0]) {
            return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:index] + 1;
        } else {
            return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:index];
        }
        } else {
            return 0;
    }
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self collectionView:collectionView identifierForCellAtIndexPath:indexPath];
    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    if ([collectionViewCell isKindOfClass:[MITNewsStoryCollectionViewCell class]]) {
        MITNewsStoryCollectionViewCell *storyCollectionViewCell = (MITNewsStoryCollectionViewCell*)collectionViewCell;
        storyCollectionViewCell.story = [self storyAtIndexPath:indexPath];
    }
    
    return collectionViewCell;
}

- (NSString*)collectionView:(UICollectionView*)collectionView identifierForCellAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    BOOL featuredStory = [self isFeaturedCategoryInSection:indexPath.section];
    
    if (!story ) {
        if (_storyUpdateInProgress) {
            return MITNewsCellIdentifierStoryLoadingMore;
        }
        if (_storyUpdatedFailed) {
            return MITNewsCellIdentifierStoryFailed;
        }
        return MITNewsCellIdentifierStoryLoadMore;
    }
    
    if (featuredStory && indexPath.item == 0) {
        return MITNewsCellIdentifierStoryJumbo;
    } else if ([story.type isEqualToString:MITNewsStoryExternalType]) {
        return MITNewsCellIdentifierStoryClip;
    } else if (story.coverImage)  {
        return MITNewsCellIdentifierStoryWithImage;
    } else {
        return MITNewsCellIdentifierStoryDek;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource canLoadMoreItemsForCategoryInSection:0] && indexPath.row + 1 == [self numberOfStoriesForCategoryInSection:indexPath.section]) {        _storyUpdateInProgress = YES;
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [self getMoreStories];

    } else {
        [self didSelectStoryAtIndexPath:indexPath];
    }
}

- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectStoryAtIndex:forCategoryInSection:)]) {
        [self.delegate viewController:self didSelectStoryAtIndex:indexPath.item forCategoryInSection:indexPath.section];
    }
}

- (void)getMoreStories
{
    if([self.dataSource canLoadMoreItemsForCategoryInSection:0]) {
        [self.dataSource loadMoreItemsForCategoryInSection:0
                                                completion:^(NSError *error) {
                                                    if (error) {
                                                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                                                        _storyUpdatedFailed = TRUE;
                                                    } else {
                                                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                                                    }
                                                    _storyUpdateInProgress = FALSE;
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        [self.collectionView reloadData];
                                                        [NSTimer scheduledTimerWithTimeInterval:2
                                                                                         target:self
                                                                                       selector:@selector(clearFailAfterTwoSeconds)
                                                                                       userInfo:nil
                                                                                        repeats:NO];
                                                    }];
                                                }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    _storyUpdatedFailed = FALSE;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.collectionView reloadData];
    }];
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForHeaderInSection:(NSInteger)section withWidth:(CGFloat)width;
{
    return 0;
}

@end
