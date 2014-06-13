#import "MITNewsCollectionViewController.h"
#import "MITCoreDataController.h"
#import "MITNewsModelController.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"

@interface MITNewsCollectionViewController () <UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>
@property (nonatomic,readonly,strong) NSMapTable *fetchedResultsControllersByCategory;
@property (nonatomic,readonly,strong) NSFetchedResultsController *categoriesFetchedResultsController;

@property (nonatomic,getter=isUpdating) BOOL updating;

@end

@implementation MITNewsCollectionViewController
@synthesize fetchedResultsControllersByCategory = _fetchedResultsControllersByCategory;
@synthesize categoriesFetchedResultsController = _categoriesFetchedResultsController;

- (instancetype)init
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(128., 128.);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self = [super initWithCollectionViewLayout:layout];

    if (self) {

    }

    return self;
}


- (void)viewDidLoad
{

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
    NSUInteger section = (NSUInteger)indexPath.section;
    NSUInteger row = (NSUInteger)indexPath.row;

    MITNewsCategory *sectionCategory = self.categoriesFetchedResultsController.fetchedObjects[section];
    NSArray *stories = [self storiesInCategory:sectionCategory];
    return stories[row];
}

- (NSFetchedResultsController*)fetchedResultControllerForSection:(NSInteger)section
{
    MITNewsCategory *category = self.categoriesFetchedResultsController.fetchedObjects[section];
    return [self.fetchedResultsControllersByCategory objectForKey:category];
}

#pragma mark Delegation Pass-Thru
- (void)didSelectStory:(MITNewsStory*)story
{
    [self.selectionDelegate newsCollectionController:self didSelectStory:story];
}

- (void)didSelectCategory:(MITNewsCategory*)category
{
    [self.selectionDelegate newsCollectionController:self didSelectCategory:category];
}

#pragma mark - Delegation
#pragma mark NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    /* Do Nothing. Here to enabled NSFRC's change tracking */
}

#pragma mark UICollectionViewDelegateFlowLayout
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.categoriesFetchedResultsController.fetchedObjects count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSFetchedResultsController *fetchController = [self fetchedResultControllerForSection:section];
    return [fetchController.fetchedObjects count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = [self storyAtIndexPath:indexPath];
    [self didSelectStory:story];
}

@end
