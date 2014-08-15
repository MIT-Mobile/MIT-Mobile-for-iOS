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

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self collectionView:collectionView identifierForCellAtIndexPath:indexPath];
    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if ([collectionViewCell isKindOfClass:[MITNewsStoryCollectionViewCell class]]) {
        MITNewsStoryCollectionViewCell *storyCollectionViewCell = (MITNewsStoryCollectionViewCell*)collectionViewCell;
        storyCollectionViewCell.story = [self storyAtIndexPath:indexPath];
        
    } else
        if (cellIdentifier == MITNewsCellIdentifierStoryLoadMore) {
            MITNewsLoadMoreCollectionViewCell *cell = (MITNewsLoadMoreCollectionViewCell *)collectionViewCell;
            if(_storyUpdateFailed) {
                cell.textLabel.text = self.errorMessage;
                cell.loadingIndicator.hidden = YES;
            } else if (_storyUpdateInProgress) {
                cell.textLabel.text = @"Loading More...";
                cell.loadingIndicator.hidden = NO;
            } else {
                cell.textLabel.text = @"Load More...";
                cell.loadingIndicator.hidden = YES;
            }
            return cell;
        }
    return collectionViewCell;
}

- (NSString *)collectionView:(UICollectionView*)collectionView identifierForCellAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self numberOfStoriesForCategoryInSection:indexPath.section] - 1 == indexPath.item && [self.dataSource canLoadMoreItemsForCategoryInSection:indexPath.section]) {
        return MITNewsCellIdentifierStoryLoadMore;
    }
    
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    BOOL featuredStory = [self isFeaturedCategoryInSection:indexPath.section];

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
        indexPath.item + 1 == [self numberOfStoriesForCategoryInSection:indexPath.section]) {
        if (!_storyUpdateInProgress) {
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
    if(!_storyUpdateInProgress && !_storyUpdateFailed) {
        _storyUpdateInProgress = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
        
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
    _storyUpdateFailed = FALSE;
    [self reloadItemAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfStoriesForCategoryInSection:0] - 1 inSection:0]];
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
