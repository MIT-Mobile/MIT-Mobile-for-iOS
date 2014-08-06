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

@interface MITNewsCategoryGridViewController ()

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
    
    if ([collectionViewCell isMemberOfClass:[UICollectionViewCell class]]) {
        // Debugging!
        if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryJumbo]) {
            collectionViewCell.contentView.backgroundColor = [UIColor blueColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryWithImage]) {
            collectionViewCell.contentView.backgroundColor = [UIColor greenColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryClip]) {
            collectionViewCell.contentView.backgroundColor = [UIColor grayColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryDek]) {
            collectionViewCell.contentView.backgroundColor = [UIColor blackColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryLoadMore]) {
            collectionViewCell.contentView.backgroundColor = [UIColor cyanColor];
            //[self getMoreStories];
        }
    } else if ([collectionViewCell isKindOfClass:[MITNewsStoryCollectionViewCell class]]) {
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

- (void)getMoreStories
{
    if([self.dataSource canLoadMoreItemsForCategoryInSection:0]) {
        [self.dataSource loadMoreItemsForCategoryInSection:0
                                                completion:^(NSError *error) {
                                                    [self.collectionView reloadData];
                                                }];
    }
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForHeaderInSection:(NSInteger)section withWidth:(CGFloat)width;
{
    return 0;
}

@end
