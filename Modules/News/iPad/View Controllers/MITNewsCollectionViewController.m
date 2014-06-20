#import "MITNewsCollectionViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITCollectionViewNewsGridLayout.h"
#import "MITNewsConstants.h"
#import "MITNewsStoryCollectionViewCell.h"

@interface MITNewsCollectionViewController () <MITCollectionViewDelegateNewsGrid, NSFetchedResultsControllerDelegate>
@property (nonatomic,readonly,strong) NSMapTable *fetchedResultsControllersByCategory;
@property (nonatomic,readonly,strong) NSFetchedResultsController *categoriesFetchedResultsController;

@property (nonatomic,getter=isUpdating) BOOL updating;

@end

@implementation MITNewsCollectionViewController
@synthesize fetchedResultsControllersByCategory = _fetchedResultsControllersByCategory;
@synthesize categoriesFetchedResultsController = _categoriesFetchedResultsController;

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
    
    [self performDataUpdate:^(NSError *error) {
        [self.collectionView reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark Properties
- (NSMapTable*)fetchedResultsControllersByCategory
{
    if (!_fetchedResultsControllersByCategory) {
        _fetchedResultsControllersByCategory = [NSMapTable weakToStrongObjectsMapTable];
    }

    return _fetchedResultsControllersByCategory;
}

- (NSFetchedResultsController*)categoriesFetchedResultsController
{
    if (!_categoriesFetchedResultsController) {
        NSFetchRequest *categories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;

        NSError *error = nil;
        BOOL fetchDidSucceed = [fetchedResultsController performFetch:&error];
        if (!fetchDidSucceed) {
            DDLogError(@"failed to fetch news categories: %@",error);
        } else {
            _categoriesFetchedResultsController = fetchedResultsController;
        }
    }

    return _categoriesFetchedResultsController;
}

- (void)setUpdating:(BOOL)updating
{
    [self setUpdating:updating animated:YES];
}

- (void)setUpdating:(BOOL)updating animated:(BOOL)animated
{
    if (_updating != updating) {
        if (updating) {
            [self willStartUpdating:animated];
        }

        _updating = updating;

        if (!_updating) {
            [self didEndUpdating:animated];
        }
    }
}

- (void)updateFailedWithError:(NSError*)error animated:(BOOL)animated
{
    self.updating = NO;
    // Display Error!!
    DDLogWarn(@"news update failed: %@", error);
}

- (void)willStartUpdating:(BOOL)animated
{
    //[self.refreshControl beginRefreshing];
    //[self setToolbarString:@"Updating..." animated:animate];
}

- (void)didEndUpdating:(BOOL)animated
{
    // Update the toolbar here?
}


#pragma mark Loading & updating, and retrieving data
// TODO: Separate out all this code! This is pasted (with a bit of artistic license)
// from the MITNewsViewController.
- (void)performDataUpdate:(void (^)(NSError *error))completion
{
    if (!self.isUpdating) {
        self.updating = YES;

        // Probably can be reimplemented some other way but, for now, this works.
        // Assumes that each of the blocks passed to the model controller below
        // will retain a strong reference to inFlightDataRequests even after this method
        // returns. When the final request completes and removes the last 'token'
        // from the in-flight request tracker, call our completion block.
        // All the callbacks should be on the main thread so race conditions should be a non-issue.
        NSMutableSet *inFlightDataRequests = [[NSMutableSet alloc] init];
        __weak MITNewsCollectionViewController *weakSelf = self;
        void (^requestCompleted)(id token, NSError *error) = ^(id token, NSError *error) {
            MITNewsCollectionViewController *blockSelf = weakSelf;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [inFlightDataRequests removeObject:token];

                if (blockSelf) {
                    if ([inFlightDataRequests count] == 0) {
                        if (error) {
                            if (completion) {
                                completion(error);
                            }
                        } else {
                            if (completion) {
                                completion(nil);
                            }
                        }

                        [blockSelf updateFailedWithError:error animated:YES];
                    }
                }
            }];
        };

        MITNewsModelController *modelController = [MITNewsModelController sharedController];
        [modelController categories:^(NSArray *categories, NSError *error) {
            [self.categoriesFetchedResultsController performFetch:nil];

            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                NSManagedObjectID *objectID = [category objectID];
                [inFlightDataRequests addObject:objectID];

                [modelController storiesInCategory:category.identifier
                                             query:nil
                                            offset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            [self invalidateStoriesInCategories:@[category]];
                                            requestCompleted(objectID,error);
                                        }];
            }];
        }];
    }
}

- (void)invalidateStoriesInCategories:(NSArray*)categories
{
    [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
        [self.fetchedResultsControllersByCategory removeObjectForKey:category];
    }];
}

- (NSArray*)storiesInCategory:(MITNewsCategory*)category
{
    // (bskinner - 2014.03.11)
    // TODO: See if NSFetchedResultsController maintains a strong reference to objects returned by -fetchedObjects.
    //  If it does not, this is going to fall flat on it's face every time since the FRC will be released
    //  the moment the local strong reference fall out of scope.
    //
    // TODO: Revisit this later and see if just a sectioned FRC would work instead of a bunch of separate ones
    //  (also look at performance issues!)
    NSFetchedResultsController *categoryFetchedResultsController = [self.fetchedResultsControllersByCategory objectForKey:category];

    if (!categoryFetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                         [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@", category];

        categoryFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                               managedObjectContext:self.managedObjectContext
                                                                                 sectionNameKeyPath:nil
                                                                                          cacheName:nil];

        NSError *error = nil;
        BOOL fetchDidSucceed = [categoryFetchedResultsController performFetch:&error];
        if (!fetchDidSucceed) {
            DDLogError(@"failed to fetch results for category '%@': %@",category,error);
        } else {
            [self.fetchedResultsControllersByCategory setObject:categoryFetchedResultsController forKey:category];
        }
    }

    return [categoryFetchedResultsController.fetchedObjects copy];
}

- (MITNewsStory*)selectedStory
{
    UICollectionView *collectionView = self.collectionView;
    NSIndexPath* selectedIndexPath = [[collectionView indexPathsForSelectedItems] firstObject];
    return [self storyAtIndexPath:selectedIndexPath];
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger categoryIndex = (NSUInteger)indexPath.section;
    NSInteger storyIndex = (NSUInteger)indexPath.row;

    MITNewsCategory *category = [self categoryForIndex:categoryIndex];
    return [self storyAtIndex:storyIndex inCategory:category];
}

- (NSFetchedResultsController*)fetchedResultControllerForSection:(NSInteger)section
{
    MITNewsCategory *category = self.categoriesFetchedResultsController.fetchedObjects[section];
    return [self.fetchedResultsControllersByCategory objectForKey:category];
}

#pragma mark - Delegation
#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    /* Do Nothing. Here to enabled NSFRC's change tracking */
}

#pragma mark UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self numberOfCategories];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    MITNewsCategory *category = [self categoryForIndex:section];
    return [self numberOfStoriesInCategory:category];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsCategory *category = [self categoryForIndex:indexPath.section];
    MITNewsStory *selectedStory = [self storyAtIndex:indexPath.item inCategory:category];
    [self didSelectStory:selectedStory];
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

#pragma mark Delegate & Data source Pass-thru
- (void)didSelectCategory:(MITNewsCategory*)category
{
    if ([self.delegate respondsToSelector:@selector(newsCollectionController:didSelectCategory:)]) {
        [self.delegate newsCollectionController:self didSelectCategory:category];
    }
}

- (void)didSelectStory:(MITNewsStory*)story
{
    if ([self.delegate respondsToSelector:@selector(newsCollectionController:didSelectStory:)]) {
        [self.delegate newsCollectionController:self didSelectStory:story];
    }
}

- (NSInteger)numberOfCategories
{
    if ([self.dataSource respondsToSelector:@selector(numberOfCategoriesInNewsCollectionController:)]) {
        return [self.dataSource numberOfCategoriesInNewsCollectionController:self];
    } else {
        return [self.categoriesFetchedResultsController.fetchedObjects count];
    }
}

- (MITNewsCategory*)categoryForIndex:(NSInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(newsCollectionController:categoryAtIndex:)]) {
        return [self.dataSource newsCollectionController:self categoryAtIndex:index];
    } else {
        return self.categoriesFetchedResultsController.fetchedObjects[index];
    }
}

- (NSInteger)numberOfStoriesInCategory:(MITNewsCategory*)category
{
    if ([self.dataSource respondsToSelector:@selector(newsCollectionController:numberOfStoriesInCategory:)]) {
        return [self.dataSource newsCollectionController:self numberOfStoriesInCategory:category];
    } else {
        NSArray *stories = [self storiesInCategory:category];
        return MAX(self.numberOfStoriesPerCategory,[stories count]);
    }
}

- (MITNewsStory*)storyAtIndex:(NSInteger)index inCategory:(MITNewsCategory*)category
{
    if ([self.dataSource respondsToSelector:@selector(newsCollectionController:storyAtIndex:inCategory:)]) {
        return [self.dataSource newsCollectionController:self storyAtIndex:index inCategory:category];
    } else {
        NSArray *stories = [self storiesInCategory:category];
        return stories[index];
    }
}

/*
@protocol MITNewsCollectionViewDelegate <NSObject>
- (NSInteger)numberOfCategoriesInNewsCollectionController:(MITNewsCollectionViewController*)collectionControllers;
- (MITNewsCategory*)newsCollectionController:(MITNewsCollectionViewController*)collectionController categoryForIndex:(NSInteger)index;

- (NSInteger)newsCollectionController:(MITNewsCollectionViewController*)collectionController numberOfStoriesInCategory:(MITNewsCategory*)category;
- (MITNewsStory*)newsCollectionController:(MITNewsCollectionViewController*)collectionController storyAtIndex:(NSInteger)index inCategory:(MITNewsCategory*)category;

- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectStory:(MITNewsStory*)story;
- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectCategory:(MITNewsCategory*)category;
@end*/

@end
