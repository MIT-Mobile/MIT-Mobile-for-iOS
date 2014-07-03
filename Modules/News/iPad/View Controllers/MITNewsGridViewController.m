#import <objc/runtime.h>

#import "MITNewsGridViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITCollectionViewNewsGridLayout.h"
#import "MITNewsConstants.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsiPadViewController.h"

@interface MITNewsGridViewController () <MITCollectionViewDelegateNewsGrid>

@end

@implementation MITNewsGridViewController
- (instancetype)init
{
    MITCollectionViewNewsGridLayout *layout = [[MITCollectionViewNewsGridLayout alloc] init];
    layout.numberOfColumns = 4;
    layout.headerHeight = 44.;
    
    self = [super initWithCollectionViewLayout:layout];

    if (self) {

    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self didLoadCollectionView:self.collectionView];
}

- (void)didLoadCollectionView:(UICollectionView*)collectionView
{
    collectionView.dataSource = self;
    collectionView.delegate = self;

    /*
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryJumboCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryJumboCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryDekCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryDekCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryClipCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryClipCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryImageCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryImageCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryHeaderReusableView bundle:nil] forSupplementaryViewOfKind:MITNewsStoryHeaderReusableView withReuseIdentifier:MITNewsStoryHeaderReusableView];
     */

    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryJumboCollectionViewCell];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryDekCollectionViewCell];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryClipCollectionViewCell];
    [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryImageCollectionViewCell];
    [collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:MITNewsStoryHeaderReusableView withReuseIdentifier:MITNewsStoryHeaderReusableView];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark Properties
- (MITNewsStory*)selectedStory
{
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath* selectedIndexPath = [[collectionView indexPathsForSelectedItems] firstObject];
    return [self storyAtIndexPath:selectedIndexPath];
}

#pragma mark - Delegation
#pragma mark UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self numberOfCategories];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self numberOfStoriesForCategoryInSection:section];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self didSelectStoryAtIndexPath:indexPath];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self collectionView:collectionView identifierForCellAtIndexPath:indexPath];
    UICollectionViewCell *collectionViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    if ([collectionViewCell isMemberOfClass:[UICollectionViewCell class]]) {
        // Debugging!
        if ([cellIdentifier isEqualToString:MITNewsStoryJumboCollectionViewCell]) {
            collectionViewCell.contentView.backgroundColor = [UIColor blueColor];
        } else if ([cellIdentifier isEqualToString:MITNewsStoryImageCollectionViewCell]) {
            collectionViewCell.contentView.backgroundColor = [UIColor greenColor];
        } else if ([cellIdentifier isEqualToString:MITNewsStoryClipCollectionViewCell]) {
            collectionViewCell.contentView.backgroundColor = [UIColor grayColor];
        } else if ([cellIdentifier isEqualToString:MITNewsStoryDekCollectionViewCell]) {
            collectionViewCell.contentView.backgroundColor = [UIColor blackColor];
        }
    } else if ([collectionViewCell isKindOfClass:[MITNewsStoryCollectionViewCell class]]) {
        MITNewsStoryCollectionViewCell *storyCollectionViewCell = (MITNewsStoryCollectionViewCell*)collectionViewCell;
        storyCollectionViewCell.story = [self storyAtIndexPath:indexPath];
    }

    return collectionViewCell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:MITNewsStoryHeaderReusableView]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:MITNewsStoryHeaderReusableView withReuseIdentifier:MITNewsStoryHeaderReusableView forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor redColor];

        return headerView;
    }

    return nil;
}

- (NSString*)collectionView:(UICollectionView*)collectionView identifierForCellAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    BOOL featuredStory = [self collectionView:collectionView layout:nil showFeaturedItemInSection:indexPath.section];

    if (featuredStory && indexPath.item == 0) {
        return MITNewsStoryJumboCollectionViewCell;
    } else if ([story.type isEqualToString:MITNewsStoryExternalType]) {
        return MITNewsStoryClipCollectionViewCell;
    } else if (story.coverImage)  {
        return MITNewsStoryImageCollectionViewCell;
    } else {
        return MITNewsStoryDekCollectionViewCell;
    }
}

#pragma mark MITCollectionViewDelegateNewsGrid
- (CGFloat)_heightForItemAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary *heights = objc_getAssociatedObject(self, _cmd);

    if (!heights) {
        heights = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, heights, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat height = 0;
    if (!heights[indexPath]) {
        height = 64. + arc4random_uniform(96);
        heights[indexPath] = @(height);
    } else {
        height = [heights[indexPath] doubleValue];
    }

    return height;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath
{
    return [self _heightForItemAtIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout showFeaturedItemInSection:(NSInteger)section
{
    if (section == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryVerticalSpanInSection:(NSInteger)section
{
    return 2;
}

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout featuredStoryHorizontalSpanInSection:(NSInteger)section
{
    return 2;
}

#pragma mark MITNewsStory delegate/datasource passthru methods
- (NSUInteger)numberOfCategories
{
    if ([self.dataSource respondsToSelector:@selector(numberOfCategoriesInViewController:)]) {
        return [self.dataSource numberOfCategoriesInViewController:self];
    } else {
        return 0;
    }
}

- (BOOL)isFeaturedCategoryInSection:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:isFeaturedCategoryInSection:)]) {
        return [self.dataSource viewController:self isFeaturedCategoryInSection:index];
    } else {
        return NO;
    }
}

- (NSString*)titleForCategoryInSection:(NSUInteger)section
{
    if ([self.dataSource respondsToSelector:@selector(viewController:titleForCategoryInSection:)]) {
        return [self.dataSource viewController:self titleForCategoryInSection:section];
    } else {
        return nil;
    }
}

- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:numberOfStoriesForCategoryInSection:)]) {
        return [self.dataSource viewController:self numberOfStoriesForCategoryInSection:index];
    } else {
        return 0;
    }
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.dataSource respondsToSelector:@selector(viewController:storyAtIndex:forCategoryInSection:)]) {
        return [self.dataSource viewController:self storyAtIndex:indexPath.item forCategoryInSection:indexPath.section];
    } else {
        return nil;
    }
}

- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectStoryAtIndex:forCategoryInSection:)]) {
        [self.delegate viewController:self didSelectStoryAtIndex:indexPath.row forCategoryInSection:indexPath.section];
    }
}

- (void)didSelectCategoryInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectCategoryInSection:)]) {
        [self.delegate viewController:self didSelectCategoryInSection:section];
    }
}

@end
