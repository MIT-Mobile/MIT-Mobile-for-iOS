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

- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)section
{
    if ([self.dataSource respondsToSelector:@selector(viewController:numberOfStoriesForCategoryInSection:)]) {
        if([self.dataSource canLoadMoreItemsForCategoryInSection:section]) {
            return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section] + 1;
        } else {
            return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:section];
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
    
    if (!story) {
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
    if ([self.dataSource canLoadMoreItemsForCategoryInSection:indexPath.section] &&
        indexPath.row + 1 == [self numberOfStoriesForCategoryInSection:indexPath.section]) {
        if (!_storyUpdateInProgress) {
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            [self getMoreStoriesForSection:indexPath.section];
        }

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

- (void)getMoreStoriesForSection:(NSInteger *)section
{
    if([self.dataSource canLoadMoreItemsForCategoryInSection:section] && !_storyUpdateInProgress) {
        _storyUpdateInProgress = YES;
        [self.dataSource loadMoreItemsForCategoryInSection:section
                                                completion:^(NSError *error) {
                                                    _storyUpdateInProgress = FALSE;
                                                    if (error) {
                                                        DDLogWarn(@"failed to refresh data source %@",self.dataSource);
                                                        _storyUpdatedFailed = TRUE;
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] - 1 inSection:section]]];
                                                            [NSTimer scheduledTimerWithTimeInterval:2
                                                                                             target:self
                                                                                           selector:@selector(clearFailAfterTwoSeconds)
                                                                                           userInfo:nil
                                                                                            repeats:NO];
                                                        }];
                                                    } else {
                                                        DDLogVerbose(@"refreshed data source %@",self.dataSource);
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            [self.collectionView reloadData];
                                                        }];
                                                    }
                                                }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:section] - 1 inSection:section]]];
        }];
    }
}

- (void)clearFailAfterTwoSeconds
{
    _storyUpdatedFailed = FALSE;
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:0] - 1 inSection:0]]];
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForHeaderInSection:(NSInteger)section withWidth:(CGFloat)width;
{
    return 0;
}

@end
