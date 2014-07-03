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

    [self collectionViewDidLoad];
}

- (void)collectionViewDidLoad
{
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    /*
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryJumboCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryJumboCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryDekCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryDekCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryClipCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryClipCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryImageCollectionViewCell bundle:nil] forCellWithReuseIdentifier:MITNewsStoryImageCollectionViewCell];
    
    [self.collectionView registerNib:[UINib nibWithNibName:MITNewsStoryHeaderReusableView bundle:nil] forSupplementaryViewOfKind:MITNewsStoryHeaderReusableView withReuseIdentifier:MITNewsStoryHeaderReusableView];
     */

    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryJumboCollectionViewCell];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryDekCollectionViewCell];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryClipCollectionViewCell];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsStoryImageCollectionViewCell];
    [self.collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:MITNewsStoryHeaderReusableView withReuseIdentifier:MITNewsStoryHeaderReusableView];
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
    return [self numberOfStoriesInCategoryAtIndex:section];
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
- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewNewsGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath
{
    return 128.;
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

- (BOOL)featuredCategoryAtIndex:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:isFeaturedCategoryAtIndex:)]) {
        return [self.dataSource viewController:self isFeaturedCategoryAtIndex:index];
    } else {
        return NO;
    }
}

- (NSString*)titleForCategoryAtIndex:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:titleForCategoryAtIndex:)]) {
        return [self.dataSource viewController:self titleForCategoryAtIndex:index];
    } else {
        return nil;
    }
}

- (NSUInteger)numberOfStoriesInCategoryAtIndex:(NSUInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(viewController:numberOfStoriesInCategoryAtIndex:)]) {
        return [self.dataSource viewController:self numberOfStoriesInCategoryAtIndex:index];
    } else {
        return 0;
    }
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.dataSource respondsToSelector:@selector(viewController:storyAtIndex:)]) {
        return [self.dataSource viewController:self storyAtIndex:indexPath.row];
    } else {
        return nil;
    }
}

- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectStoryAtIndexPath:)]) {
        [self.delegate viewController:self didSelectStoryAtIndexPath:indexPath];
    }
}

- (void)didSelectCategoryAtIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectCategoryAtIndex:)]) {
        [self.delegate viewController:self didSelectCategoryAtIndex:index];
    }
}

@end
