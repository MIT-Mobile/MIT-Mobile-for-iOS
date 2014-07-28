#import <objc/runtime.h>

#import "MITNewsGridViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITCollectionViewGridLayout.h"
#import "MITNewsConstants.h"
#import "MITNewsStoryCollectionViewCell.h"
#import "MITNewsiPadViewController.h"

@interface MITNewsGridViewController () <MITCollectionViewDelegateNewsGrid>
@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@end

@implementation MITNewsGridViewController
- (instancetype)init
{
    MITCollectionViewGridLayout *layout = [[MITCollectionViewGridLayout alloc] init];
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
    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];
}

- (void)didLoadCollectionView:(UICollectionView*)collectionView
{
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.backgroundView = nil;

    const BOOL debug = YES;

    if (!debug) {
        [collectionView registerNib:[UINib nibWithNibName:MITNewsCellIdentifierStoryJumbo bundle:nil] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryJumbo];
    
        [collectionView registerNib:[UINib nibWithNibName:MITNewsCellIdentifierStoryDek bundle:nil] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryDek];
    
        [collectionView registerNib:[UINib nibWithNibName:MITNewsCellIdentifierStoryClip bundle:nil] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryClip];
    
        [collectionView registerNib:[UINib nibWithNibName:MITNewsCellIdentifierStoryWithImage bundle:nil] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryWithImage];
        
        [collectionView registerNib:[UINib nibWithNibName:MITNewsCellIdentifierStoryLoadMore bundle:nil] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryLoadMore];
    
        [collectionView registerNib:[UINib nibWithNibName:MITNewsReusableViewIdentifierSectionHeader bundle:nil] forSupplementaryViewOfKind:MITNewsReusableViewIdentifierSectionHeader withReuseIdentifier:MITNewsReusableViewIdentifierSectionHeader];
    } else {
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryJumbo];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryDek];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryClip];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryWithImage];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:MITNewsCellIdentifierStoryLoadMore];
        [collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:MITNewsReusableViewIdentifierSectionHeader withReuseIdentifier:MITNewsReusableViewIdentifierSectionHeader];
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.managedObjectContext) {
        self.managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType trackChanges:NO];
    }

    [self updateLayoutForOrientation:self.interfaceOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateLayoutForOrientation:toInterfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


#pragma mark Properties
- (MITNewsStory*)selectedStory
{
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath* selectedIndexPath = [[collectionView indexPathsForSelectedItems] firstObject];
    return [self storyAtIndexPath:selectedIndexPath];
}

#pragma mark - Responding to UI events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    NSIndexPath *categoryIndexPath = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

    if (categoryIndexPath && categoryIndexPath.section != 0) {
        [self didSelectCategoryInSection:[categoryIndexPath indexAtPosition:0]];
    }
}

- (void)updateLayoutForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([self.collectionViewLayout isKindOfClass:[MITCollectionViewGridLayout class]]) {
        MITCollectionViewGridLayout *gridLayout = (MITCollectionViewGridLayout*)self.collectionViewLayout;
        if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
            gridLayout.numberOfColumns = 3;
        } else {
            gridLayout.numberOfColumns = 5;
        }
    }

    [self.collectionViewLayout invalidateLayout];
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
        if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryJumbo]) {
            collectionViewCell.contentView.backgroundColor = [UIColor blueColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryWithImage]) {
            collectionViewCell.contentView.backgroundColor = [UIColor greenColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryClip]) {
            collectionViewCell.contentView.backgroundColor = [UIColor grayColor];
        } else if ([cellIdentifier isEqualToString:MITNewsCellIdentifierStoryDek]) {
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
    if ([kind isEqualToString:MITNewsReusableViewIdentifierSectionHeader]) {
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:MITNewsReusableViewIdentifierSectionHeader withReuseIdentifier:MITNewsReusableViewIdentifierSectionHeader forIndexPath:indexPath];
        headerView.backgroundColor = [UIColor redColor];
        UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
        if (!recognizer) {
            recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
            [headerView addGestureRecognizer:recognizer];
        }
        
        // Keep track of the gesture recognizers we create so we can remove
        // them later
        [self.gestureRecognizersByView setObject:recognizer forKey:headerView];
        
        NSIndexPath *categoryIndexPath = [NSIndexPath indexPathWithIndex:indexPath.section];
        [self.categoriesByGestureRecognizer setObject:categoryIndexPath forKey:recognizer];

        return headerView;
    }

    return nil;
}

- (NSString*)collectionView:(UICollectionView*)collectionView identifierForCellAtIndexPath:(NSIndexPath*)indexPath
{
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
        height = 96. + arc4random_uniform(96);
        heights[indexPath] = @(height);
    } else {
        height = [heights[indexPath] doubleValue];
    }

    return height;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout heightForItemAtIndexPath:(NSIndexPath*)indexPath withWidth:(CGFloat)width
{
    return [self _heightForItemAtIndexPath:indexPath];
}

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout featuredStoryVerticalSpanInSection:(NSInteger)section
{
    if ([self isFeaturedCategoryInSection:section]) {
        return 2;
    } else {
        return 0;
    }
}

- (NSUInteger)collectionView:(UICollectionView*)collectionView layout:(MITCollectionViewGridLayout*)layout featuredStoryHorizontalSpanInSection:(NSInteger)section
{
    if ([self isFeaturedCategoryInSection:section]) {
        return 2;
    } else {
        return 0;
    }
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
        [self.delegate viewController:self didSelectStoryAtIndex:indexPath.item forCategoryInSection:indexPath.section];
    }
}

- (void)didSelectCategoryInSection:(NSUInteger)section
{
    if ([self.delegate respondsToSelector:@selector(viewController:didSelectCategoryInSection:)]) {
        [self.delegate viewController:self didSelectCategoryInSection:section];
    }
}

@end
