#import <objc/runtime.h>
#import "MITNewsViewController.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsStoryViewController.h"
#import "MITNewsCategoryViewController.h"
#import "MITNewsModelController.h"
#import "MITNewsStoryCell.h"
#import "MITNewsLoadMoreTableViewCell.h"
#import "MITDisclosureHeaderView.h"
#import "UIImageView+WebCache.h"
#import "MITLoadingActivityView.h"

#import "MITNewsConstants.h"
#import "MITAdditions.h"
#import "UIScrollView+SVPullToRefresh.h"

static NSUInteger MITNewsDefaultNumberOfFeaturedStories = 5;
static NSString* const MITNewsCachedLayoutCellsAssociatedObjectKey = @"MITNewsCachedLayoutCells";

@interface MITNewsViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate,UIAlertViewDelegate>
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,strong) NSDate *lastUpdated;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;      // Should contain @{<UIView> : <UIGestureRecognizer>} mappings
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer; // Should contain @{<UIGestureRecognizer> : <NSManagedObjectID>} mappings
@property (nonatomic,strong) NSMutableDictionary *cachedStoriesByCategory; // Needs to be replaced by something else, maybe just using another FRC

@property (nonatomic,strong) NSFetchedResultsController *featuredStoriesFetchedResultsController;
@property (nonatomic,strong) NSFetchedResultsController *categoriesFetchedResultsController;

#pragma mark Searching
@property (nonatomic,getter = isSearching) BOOL searching;
@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSArray *searchResults;

@property (nonatomic,readonly) MITNewsStory *selectedStory;

- (void)loadFetchedResultsControllers;

#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingWithError:(NSError*)error animated:(BOOL)animate;
- (void)setToolbarString:(NSString*)string animated:(BOOL)animated;

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender;
@end

@interface MITNewsViewController (DynamicTableViewCellsShared)
#pragma mark private(-ish)
// I think these methods shouldn't require modification to be used
// in another class.
- (NSMutableDictionary*)_cachedLayoutCellsForTableView:(UITableView*)tableView;
- (UITableViewCell*)_tableView:(UITableView*)tableView dequeueReusableLayoutCellWithIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath;
- (NSInteger)_tableView:(UITableView*)tableView minimumHeightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)_tableView:(UITableView*)tableView registerClass:(Class)nilOrClass forCellReuseIdentifier:(NSString*)cellReuseIdentifier;
- (void)_tableView:(UITableView*)tableView registerNib:(UINib*)nilOrNib forCellReuseIdentifier:(NSString*)cellReuseIdentifier;
@end

@interface MITNewsViewController (DynamicTableViewCells)
// You'll need to modify these for them to work in another class
// should be delegated out
- (NSInteger)_tableView:(UITableView *)tableView primitiveNumberOfRowsInSection:(NSInteger)section;
- (id)_tableView:(UITableView*)tableView representedObjectForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)_tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
- (NSString*)_tableView:(UITableView*)tableView reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath;
@end


@interface MITNewsViewController (NewsSearching)
// These methods are in the order they will (at least, should) be called in
- (void)beginSearchingAnimated:(BOOL)animated;
- (void)willLoadSearchResultsAnimated:(BOOL)animate;

- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion;
- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion;

- (void)didLoadResultsForSearchWithError:(NSError*)error animated:(BOOL)animate;
- (void)endSearchingAnimated:(BOOL)animated;
@end


@implementation MITNewsViewController {
    CGPoint _contentOffsetToRestoreAfterSearching;
    id _storySearchInProgressToken;
}

#pragma mark UI Element text attributes
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil managedObjectContext:nil];
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil managedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return NO;
}

#pragma mark Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.numberOfStoriesPerCategory = 3;
    self.showFeaturedStoriesSection = YES;

    [self.tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:MITNewsCategoryHeaderIdentifier];
    
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];

    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlWasTriggered:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{

    [super viewWillAppear:animated];
    
    if (!self.isSearching) {
        [self loadFetchedResultsControllers];

        if (!self.featuredStoriesFetchedResultsController.fetchedObjects || !self.categoriesFetchedResultsController.fetchedObjects) {
            NSError *fetchError = nil;
            [self.featuredStoriesFetchedResultsController performFetch:&fetchError];
            if (fetchError) {
                DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
            }

            fetchError = nil;
            [self.categoriesFetchedResultsController performFetch:&fetchError];
            if (fetchError) {
                DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
            }

            [self.tableView reloadData];
        }
        
        // Only make sure the toolbar is visible if we are not searching
        // otherwise, returning after viewing a story pops it up
        [self.navigationController setToolbarHidden:NO animated:animated];

        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            self.navigationController.toolbar.barStyle = UIBarStyleBlack;
            self.navigationController.toolbar.translucent = NO;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.isSearching) {
        if (!self.lastUpdated) {
            __weak MITNewsViewController *weakSelf = self;
            [self performDataUpdate:^(NSError *error){
                MITNewsViewController *blockSelf = weakSelf;
                if (blockSelf) {
                    [self.tableView reloadData];
                }
            }];
        } else {
            NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                                toDate:[NSDate date]];
            NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
            [self setToolbarString:updateText animated:animated];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];

    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);

    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;
            MITNewsStory *story = [self selectedStory];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext existingObjectWithID:[story objectID] error:nil];
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else if ([segue.identifier isEqualToString:@"showCategoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsCategoryViewController class]]) {
            MITNewsCategoryViewController *storiesViewController = (MITNewsCategoryViewController*)destinationViewController;

            UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;
            NSManagedObjectID *categoryObjectID = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            storiesViewController.managedObjectContext = managedObjectContext;
            [storiesViewController setCategoryWithObjectID:categoryObjectID];
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsCategoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

#pragma mark Notifications
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark View Orientation
- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Property Setters & Getters
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }

    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark - Managing states
#pragma mark Updating
#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate
{
    if (!self.isUpdating) {
        self.updating = YES;
        
        if (!self.isSearching) {
            [self.refreshControl beginRefreshing];
            [self setToolbarString:@"Updating..." animated:animate];
        }
    }
}

- (void)endUpdatingAnimated:(BOOL)animate
{
    [self endUpdatingWithError:nil animated:animate];
}

- (void)endUpdatingWithError:(NSError*)error animated:(BOOL)animate
{
    if (self.isUpdating) {
        if (!self.isSearching) {
            
            [self.featuredStoriesFetchedResultsController performFetch:nil];
            [self.categoriesFetchedResultsController performFetch:nil];
            
            
            if (!error) {
                self.lastUpdated = [NSDate date];
                
                NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                                    toDate:[NSDate date]];
                NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
                [self setToolbarString:updateText animated:animate];
            } else {
                [self setToolbarString:@"Update Failed" animated:animate];
            }
            
            [self.refreshControl endRefreshing];
        }
        
        self.updating = NO;
    }
}

#pragma mark UI Helper
- (void)setToolbarString:(NSString*)string animated:(BOOL)animated
{
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    updatingLabel.text = string;

    if (self.navigationController.toolbar.barStyle == UIBarStyleBlack) {
        updatingLabel.textColor = [UIColor whiteColor];
    } else {
        updatingLabel.textColor = [UIColor blackColor];
    }

    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];
    
    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}


#pragma mark - Responding to UI events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    NSManagedObjectID *categoryObjectID = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

    if (categoryObjectID) {
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *localCategory = (MITNewsCategory*)[self.managedObjectContext existingObjectWithID:categoryObjectID error:nil];
            DDLogVerbose(@"Recieved tap on section header for category with name '%@'",localCategory.name);
        }];

        [self performSegueWithIdentifier:@"showCategoryDetail" sender:gestureRecognizer];
    }

}

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    [self beginSearchingAnimated:NO];
}

- (IBAction)refreshControlWasTriggered:(UIRefreshControl*)sender
{    __weak MITNewsViewController *weakSelf = self;
    [self performDataUpdate:^(NSError *error){
        MITNewsViewController *blockSelf = weakSelf;
        if (blockSelf) {
            [blockSelf.tableView reloadData];
        }
    }];
}

#pragma mark Loading & updating, and retrieving data
- (void)loadFetchedResultsControllers
{
    // Featured fetched results controller
    if (self.showFeaturedStoriesSection && !self.featuredStoriesFetchedResultsController) {
        NSFetchRequest *featuredStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        featuredStories.predicate = [NSPredicate predicateWithFormat:@"featured == YES"];
        featuredStories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                            [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:featuredStories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.featuredStoriesFetchedResultsController = fetchedResultsController;
    }

    if (!self.categoriesFetchedResultsController) {
        NSFetchRequest *categories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.categoriesFetchedResultsController = fetchedResultsController;
    }
}

- (void)performDataUpdate:(void (^)(NSError *error))completion
{
    if (!self.isUpdating) {
        [self beginUpdatingAnimated:YES];

        // Probably can be reimplemented some other way but, for now, this works.
        // Assumes that each of the blocks passed to the model controller below
        // will retain a strong reference to inFlightDataRequests even after this method
        // returns. When the final request completes and removes the last 'token'
        // from the in-flight request tracker, call our completion block.
        // All the callbacks should be on the main thread so race conditions should be a non-issue.
        NSMutableSet *inFlightDataRequests = [[NSMutableSet alloc] init];
        __weak MITNewsViewController *weakSelf = self;
        void (^requestCompleted)(id token, NSError *error) = ^(id token, NSError *error) {
            MITNewsViewController *blockSelf = weakSelf;
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

                        [blockSelf endUpdatingWithError:error animated:YES];
                    }
                }
            }];
        };

        MITNewsModelController *modelController = [MITNewsModelController sharedController];

        [inFlightDataRequests addObject:MITNewsStoryFeaturedStoriesRequestToken];
        [modelController featuredStoriesWithOffset:0
                                             limit:MITNewsDefaultNumberOfFeaturedStories
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            requestCompleted(MITNewsStoryFeaturedStoriesRequestToken,error);
                                        }];

        [modelController categories:^(NSArray *categories, NSError *error) {
            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                NSManagedObjectID *objectID = [category objectID];
                [inFlightDataRequests addObject:objectID];

                [modelController storiesInCategory:category.identifier
                                             query:nil
                                            offset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            requestCompleted(objectID,error);
                                        }];
            }];
        }];
    }
}

- (NSArray*)storiesInCategory:(MITNewsCategory*)category
{
    if (!self.cachedStoriesByCategory) {
        self.cachedStoriesByCategory = [[NSMutableDictionary alloc] init];
    }

    NSArray *cachedStories = self.cachedStoriesByCategory[[category objectID]];

    if (!cachedStories) {
        __block NSArray *stories = nil;
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *blockCategory = (MITNewsCategory*)[self.managedObjectContext objectWithID:[category objectID]];
            stories = [blockCategory.stories sortedArrayUsingDescriptors:sortDescriptors];
        }];

        self.cachedStoriesByCategory[[category objectID]] = stories;
        cachedStories = stories;
    }

    return cachedStories;
}

- (MITNewsStory*)selectedStory
{
    UITableView *tableView = nil;

    if (self.searchDisplayController.isActive) {
        tableView = self.searchDisplayController.searchResultsTableView;
    } else {
        tableView = self.tableView;
    }

    NSIndexPath* selectedIndexPath = [tableView indexPathForSelectedRow];
    return [self storyAtIndexPath:selectedIndexPath inTableView:tableView];
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView
{
    NSUInteger section = (NSUInteger)indexPath.section;
    NSUInteger row = (NSUInteger)indexPath.row;

    if (tableView == self.tableView) {
        MITNewsStory *story = nil;

        if (self.showFeaturedStoriesSection && (section == 0)) {
            story = [self.featuredStoriesFetchedResultsController objectAtIndexPath:indexPath];
        } else {
            if (self.showFeaturedStoriesSection) {
                section -= 1;
            }

            MITNewsCategory *sectionCategory = self.categoriesFetchedResultsController.fetchedObjects[section];
            NSArray *stories = [self storiesInCategory:sectionCategory];
            story = stories[row];
        }

        return story;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[row];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

#pragma mark - NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    /* Do Nothing. Here to enabled NSFRC's change tracking */
}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return 44.;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            if ([self.featuredStoriesFetchedResultsController.fetchedObjects count]) {
                MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:MITNewsCategoryHeaderIdentifier];
                headerView.titleLabel.text = @"Featured";
                headerView.accessoryView.hidden = YES;

                UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
                if (recognizer) {
                    [headerView removeGestureRecognizer:recognizer];
                    [self.categoriesByGestureRecognizer removeObjectForKey:recognizer];
                    [self.gestureRecognizersByView removeObjectForKey:headerView];
                }
                
                return headerView;
            } else {
                return nil;
            }
        } else if ([self.categoriesFetchedResultsController.fetchedObjects count]) {
            MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:MITNewsCategoryHeaderIdentifier];
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
            if (!recognizer) {
                recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
                [headerView addGestureRecognizer:recognizer];
            }

            // Keep track of the gesture recognizers we create so we can remove
            // them later
            [self.gestureRecognizersByView setObject:recognizer forKey:headerView];

            NSArray *categories = [self.categoriesFetchedResultsController fetchedObjects];
            [self.categoriesByGestureRecognizer setObject:[categories[section] objectID] forKey:recognizer];

            __block NSString *categoryName = nil;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[categories[section] objectID]];
                categoryName = category.name;
            }];

            headerView.titleLabel.text = categoryName;
            headerView.accessoryView.hidden = NO;
            return headerView;
        } else {
            return nil;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        [storyCell.storyImageView cancelCurrentImageLoad];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        // Our normal table view is only made up of the various MITNewsStoryCells
        // so we can just calculate the height for each one
        return [self _tableView:tableView minimumHeightForRowAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSString *identifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
        if ([identifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
            return 44.; // Fixed height for the load more cells
        } else {
            return [self _tableView:tableView minimumHeightForRowAtIndexPath:indexPath];
        }
    }

    return UITableViewAutomaticDimension;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            if (_storySearchInProgressToken) {
                return NO;
            }
        }
    } else {
        __block BOOL isExternalStory = NO;
        __block NSURL *externalURL = nil;
        MITNewsStory *story = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];

        [self.managedObjectContext performBlockAndWait:^{
            if ([story.type isEqualToString:MITNewsStoryExternalType]) {
                isExternalStory = YES;
                externalURL = story.sourceURL;
            }
        }];

        return (!isExternalStory || [[UIApplication sharedApplication] canOpenURL:externalURL]);
    }

    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id representedObject = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    if (representedObject && [representedObject isKindOfClass:[MITNewsStory class]]) {
        MITNewsStory *story = representedObject;

        __block BOOL isExternalStory = NO;
        __block NSURL *externalURL = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if ([story.type isEqualToString:MITNewsStoryExternalType]) {
                isExternalStory = YES;
                externalURL = story.sourceURL;
            }
        }];

        if (isExternalStory) {
            NSString *message = [NSString stringWithFormat:@"Open in Safari?"];
            UIAlertView *willOpenInExternalBrowserAlertView = [[UIAlertView alloc] initWithTitle:message message:[externalURL absoluteString] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
            [willOpenInExternalBrowserAlertView show];
        } else {
            [self performSegueWithIdentifier:@"showStoryDetail" sender:tableView];
        }
    } else {
        NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
        if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
            if (self.searchDisplayController.searchResultsTableView == tableView && !_storySearchInProgressToken) {
                __weak UITableView *weakTableView = self.searchDisplayController.searchResultsTableView;
                [self loadStoriesForQuery:self.searchQuery
                                   loaded:^(NSString *query, NSError *error) {
                                       UITableView *blockTableView = weakTableView;
                                       if (blockTableView) {
                                           [blockTableView reloadData];
                                       }
                                   }];
            }

            [tableView reloadData];
        }
    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSInteger numberOfSections = 0;

        if (self.showFeaturedStoriesSection && self.featuredStoriesFetchedResultsController.fetchedObjects) {
            numberOfSections += 1;
        }

        numberOfSections += [self.categoriesFetchedResultsController.fetchedObjects count];
        return numberOfSections;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self _tableView:tableView primitiveNumberOfRowsInSection:section];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];

    NSAssert(identifier,@"[%@] missing UITableViewCell identifier in %@",self,NSStringFromSelector(_cmd));

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    [self _tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        __block NSURL *url = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *story = [self selectedStory];
            if (story) {
                url = story.sourceURL;
            }
        }];

        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }

    UITableView *activeTableView = nil;
    if (self.isSearching) {
        activeTableView = self.searchDisplayController.searchResultsTableView;
    } else {
        activeTableView = self.tableView;
    }

    NSIndexPath *selectedIndexPath = [activeTableView indexPathForSelectedRow];
    [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

@end



#pragma mark Data Source/Delegate Helper Methods
@implementation MITNewsViewController (DynamicTableViewCellsShared)
- (NSMutableDictionary*)_cachedLayoutCellsForTableView:(UITableView*)tableView
{
    const void *objectKey = (__bridge const void *)MITNewsCachedLayoutCellsAssociatedObjectKey;
    NSMapTable *cachedLayoutCells = objc_getAssociatedObject(tableView,objectKey);
    
    if (!cachedLayoutCells) {
        cachedLayoutCells = [NSMapTable weakToStrongObjectsMapTable];
        objc_setAssociatedObject(tableView, objectKey, cachedLayoutCells, OBJC_ASSOCIATION_RETAIN);
    }
    
    NSMutableDictionary *sizingCellsByIdentifier = [cachedLayoutCells objectForKey:tableView];
    if (!sizingCellsByIdentifier) {
        sizingCellsByIdentifier = [[NSMutableDictionary alloc] init];
        [cachedLayoutCells setObject:sizingCellsByIdentifier forKey:tableView];
    }
    
    return sizingCellsByIdentifier;
}

- (void)_tableView:(UITableView*)tableView registerClass:(Class)nilOrClass forCellReuseIdentifier:(NSString*)cellReuseIdentifier
{
    // Order is important! This depends on !nilOrClass short-circuiting the
    // OR.
    NSParameterAssert(!nilOrClass || class_isMetaClass(object_getClass(nilOrClass)));
    NSParameterAssert(!nilOrClass || [nilOrClass isSubclassOfClass:[UITableViewCell class]]);
    
    [tableView registerClass:nilOrClass forCellReuseIdentifier:cellReuseIdentifier];
    
    NSMutableDictionary *cachedLayoutCells = [self _cachedLayoutCellsForTableView:tableView];
    if (nilOrClass) {
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            UITableViewCell *layoutCell = (UITableViewCell*)[[[nilOrClass class] alloc] init];
            cachedLayoutCells[cellReuseIdentifier] = layoutCell;
        }
    } else {
        [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
    }
}

- (void)_tableView:(UITableView*)tableView registerNib:(UINib*)nilOrNib forCellReuseIdentifier:(NSString*)cellReuseIdentifier
{
    NSParameterAssert(!nilOrNib || [nilOrNib isKindOfClass:[UINib class]]);
    
    [tableView registerNib:nilOrNib forCellReuseIdentifier:cellReuseIdentifier];
    
    NSMutableDictionary *cachedLayoutCells = [self _cachedLayoutCellsForTableView:tableView];
    
    if (nilOrNib) {
        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            UITableViewCell *layoutCell = [[nilOrNib instantiateWithOwner:nil options:nil] firstObject];
            NSAssert([layoutCell isKindOfClass:[UITableViewCell class]], @"class must be a subclass of %@",NSStringFromClass([UITableViewCell class]));
            cachedLayoutCells[cellReuseIdentifier] = layoutCell;
        }
    } else {
        [cachedLayoutCells removeObjectForKey:cellReuseIdentifier];
    }
}

- (UITableViewCell*)_tableView:(UITableView*)tableView dequeueReusableLayoutCellWithIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary *cachedLayoutCellsForTableView = [self _cachedLayoutCellsForTableView:tableView];
    
    UITableViewCell *layoutCell = cachedLayoutCellsForTableView[reuseIdentifier];
    
    if (!layoutCell) {
        layoutCell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        NSAssert(layoutCell, @"you must register a nib or class with for reuse identifier '%@'",reuseIdentifier);
        cachedLayoutCellsForTableView[reuseIdentifier] = layoutCell;
    }
    
    CGSize cellSize = [layoutCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    layoutCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    layoutCell.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), cellSize.height + 1.);
    
    if (![layoutCell isDescendantOfView:tableView]) {
        [tableView addSubview:layoutCell];
    } else {
        [layoutCell prepareForReuse];
    }
    
    layoutCell.hidden = YES;
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    return layoutCell;
}

- (NSInteger)_tableView:(UITableView*)tableView minimumHeightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    UITableViewCell *layoutCell = [self _tableView:tableView dequeueReusableLayoutCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSAssert(layoutCell, @"unable to get a valid layout cell!");
    if ([self respondsToSelector:@selector(_tableView:configureCell:forRowAtIndexPath:)]) {
        [self _tableView:tableView configureCell:layoutCell forRowAtIndexPath:indexPath];
    } else if ([layoutCell respondsToSelector:@selector(setRepresentedObject:)]) {
        id representedObejct = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
        [layoutCell performSelector:@selector(setRepresentedObject:) withObject:representedObejct];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"unable to configure cell in table view %@ at %@",tableView,indexPath]
                                     userInfo:nil];
    }
    
    [layoutCell setNeedsUpdateConstraints];
    [layoutCell setNeedsLayout];
    [layoutCell layoutIfNeeded];
    
    CGSize rowSize = [layoutCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return (ceil(rowSize.height) + 1.);
}
@end

@implementation MITNewsViewController (DynamicTableViewCells)
- (NSString*)_tableView:(UITableView*)tableView reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    if (story) {
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            
            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                if (newsStory.coverImage) {
                    identifier = MITNewsStoryExternalCellIdentifier;
                } else {
                    identifier = MITNewsStoryExternalNoImageCellIdentifier;
                }
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
        
        return identifier;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return MITNewsLoadMoreCellIdentifier;
    } else {
        return nil;
    }
}

// Should delegate
- (id)_tableView:(UITableView*)tableView representedObjectForRowAtIndexPath:(NSIndexPath*)indexPath {
    return [self storyAtIndexPath:indexPath inTableView:tableView];
}

// Should delegate
- (NSInteger)_tableView:(UITableView *)tableView primitiveNumberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            NSArray *stories = [self.featuredStoriesFetchedResultsController fetchedObjects];
            return MIN(MITNewsDefaultNumberOfFeaturedStories,[stories count]);
        } else if (self.categoriesFetchedResultsController.fetchedObjects) {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }
            
            MITNewsCategory *category = self.categoriesFetchedResultsController.fetchedObjects[section];
            NSArray *storiesInCategory = [self storiesInCategory:category];
            return MIN(self.numberOfStoriesPerCategory,[storiesInCategory count]);
        }
        
        return 0;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([self.searchResults count]) {
            return [self.searchResults count] + 1;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

// Should delegate
- (void)_tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (self.searchDisplayController.searchResultsTableView == tableView) {
            cell.textLabel.enabled = !_storySearchInProgressToken;

            if (_storySearchInProgressToken) {
                UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [view startAnimating];
                cell.accessoryView = view;
            } else {
                cell.accessoryView = nil;
            }
        }
    } else {
        MITNewsStory *story = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    
        if (story && [cell isKindOfClass:[MITNewsStoryCell class]]) {
            MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsStory *contextStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
                storyCell.story = contextStory;
            }];
        }
    }
}

@end


@implementation MITNewsViewController (NewsSearching)
- (void)beginSearchingAnimated:(BOOL)animated
{
    if (!self.isSearching) {
        _contentOffsetToRestoreAfterSearching = self.tableView.contentOffset;

        UISearchBar *searchBar = self.searchDisplayController.searchBar;
        searchBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 44.);
        [searchBar sizeToFit];
        self.tableView.tableHeaderView = searchBar;

        [UIView animateWithDuration:(animated ? 0.33 : 0)
                              delay:0.
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             [self.tableView scrollRectToVisible:searchBar.frame animated:NO];
                         } completion:^(BOOL finished) {
                             [searchBar becomeFirstResponder];
                             [self.navigationController setToolbarHidden:YES animated:NO];

                             self.searching = YES;
                         }];
    }
}


// Replace with a dedicated paging helper
- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion
{
    // Default behavior is to automatically page the results (if the query matches the current
    //  one). If the two queries do not match, the search results will be cleared first.
    // Passing 'NO' for shouldLoadNextPage should always clear the results and reload the first
    //  page of stories.
    [self loadStoriesForQuery:query shouldLoadNextPage:YES completion:completion];
}

- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion
{
    if (_storySearchInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored upon completion");
    }

    NSUUID *requestUUID = [NSUUID UUID];
    self->_storySearchInProgressToken = requestUUID;

    if ([query length] == 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (requestUUID == _storySearchInProgressToken) {
                self.searchQuery = nil;
                self.searchResults = @[];

                [self willLoadSearchResultsAnimated:YES];

                if (completion) {
                    completion(query,nil);
                }

                [self didLoadResultsForSearchWithError:nil animated:YES];

                _storySearchInProgressToken = nil;
            }
        }];
    } else {
        NSUInteger offset = 0;

        if (![self.searchQuery isEqualToString:query]) {
            self.searchResults = @[];
            offset = 0;
        } else if (loadNextPage) {
            offset = [self.searchResults count];
        }

        self.searchQuery = query;

        [self willLoadSearchResultsAnimated:YES];

        __weak MITNewsViewController *weakSelf = self;
        [[MITNewsModelController sharedController] storiesInCategory:nil query:query offset:offset limit:20 completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
            MITNewsViewController *blockSelf = weakSelf;
            if (blockSelf) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    BOOL isSameRequestToken = (blockSelf->_storySearchInProgressToken == requestUUID);
                    if (isSameRequestToken) {
                        blockSelf->_storySearchInProgressToken = nil;

                        __block NSArray *localStories = nil;
                        [blockSelf.managedObjectContext performBlockAndWait:^{
                            localStories = [blockSelf.managedObjectContext transferManagedObjects:stories];
                        }];

                        // If we are loading the next (or additional pages, in general)
                        // we should append the results onto the existing search results.
                        // Otherwise, just do a wholesale replacement of the content.
                        if (loadNextPage) {
                            // Should have the same exact results as passing loadNextPage == NO,
                            //  if searchResults is currently nil or empty
                            NSMutableArray *newSearchResults = [NSMutableArray arrayWithArray:self.searchResults];
                            NSRange insertionRange = NSMakeRange(offset, [stories count]);
                            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];

                            if (offset < [newSearchResults count]) {
                                [newSearchResults removeObjectsInRange:NSMakeRange(offset, [newSearchResults count])];
                            }

                            [newSearchResults insertObjects:stories atIndexes:insertedIndexes];
                            blockSelf.searchResults = newSearchResults;
                        } else {
                            blockSelf.searchResults = localStories;
                        }


                        [self didLoadResultsForSearchWithError:error animated:YES];

                        if (completion) {
                            if (error) {
                                completion(nil,error);
                            } else {
                                completion(query,nil);
                            }
                        }

                    }
                }];
            }
        }];
    }
}


- (void)willLoadSearchResultsAnimated:(BOOL)animate
{
    if (self.searchDisplayController.isActive) {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;

        if (![self.searchResults count]) {
            NSUInteger tag = 0xdeadbeef;
            MITLoadingActivityView *loadingActivityView = [[MITLoadingActivityView alloc] initWithFrame:tableView.bounds];
            loadingActivityView.tag = tag;
            [tableView addSubview:loadingActivityView];
        }
    }
}

- (void)didLoadResultsForSearchWithError:(NSError*)error animated:(BOOL)animate
{
    if (self.searchDisplayController.isActive) {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;

        NSUInteger tag = 0xdeadbeef;
        UIView *view = [tableView viewWithTag:tag];
        [view removeFromSuperview];
    }
}

- (void)endSearchingAnimated:(BOOL)animated
{
    if (self.isSearching) {
        UISearchBar *searchBar = self.searchDisplayController.searchBar;

        [UIView animateWithDuration:(animated ? 0.33 : 0)
                              delay:0.
                            options:UIViewAnimationCurveEaseIn
                         animations:^{
                             if (animated) {
                                 // Add in the search bar's height otherwise we will come up short
                                 CGPoint targetPoint = _contentOffsetToRestoreAfterSearching;
                                 targetPoint.y += CGRectGetHeight(searchBar.frame);
                                 [self.tableView setContentOffset:targetPoint animated:NO];
                             } else {
                                 [self.tableView setContentOffset:_contentOffsetToRestoreAfterSearching animated:NO];
                                 self.tableView.tableHeaderView = nil;
                             }

                             [self.navigationController setToolbarHidden:NO animated:NO];
                         } completion:^(BOOL finished) {
                             if (animated) {
                                 self.tableView.tableHeaderView = nil;

                                 // Now that the search bar is gone, correct out content offset to the
                                 // correct one.
                                 [self.tableView setContentOffset:_contentOffsetToRestoreAfterSearching animated:NO];
                             }
                             
                             self.searchQuery = nil;
                             self.searchResults = nil;
                             _contentOffsetToRestoreAfterSearching = CGPointZero;
                             self.searching = NO;
                         }];
    }
}

#pragma mark UISearchDisplayDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [self _tableView:tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self _tableView:tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self _tableView:tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [self _tableView:tableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self loadStoriesForQuery:nil loaded:^(NSString *query, NSError *error) {
        [controller.searchResultsTableView reloadData];
    }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [self endSearchingAnimated:NO];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if ([searchString length] == 0) {
        [self loadStoriesForQuery:nil loaded:^(NSString *query, NSError *error) {
            [controller.searchResultsTableView reloadData];
        }];
        return YES;
    } else if ([self.searchResults count]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSString *searchQuery = searchBar.text;

    __weak UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    [self loadStoriesForQuery:searchQuery loaded:^(NSString *query, NSError *error) {
        [searchDisplayController.searchResultsTableView reloadData];
    }];
}

@end

