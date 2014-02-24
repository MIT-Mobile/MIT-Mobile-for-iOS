#import <objc/runtime.h>

#import "MITNewsCategoryViewController.h"
#import "MITNewsStoryCell.h"
#import "MITCoreData.h"

#import "MITAdditions.h"
#import "MITDisclosureHeaderView.h"

#import "MITNewsModelController.h"
#import "MITNewsImage.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsCategory.h"
#import "MITNewsStory.h"

#import "UIImageView+WebCache.h"
#import "MITLoadingActivityView.h"
#import "MITNewsConstants.h"
#import "MITNewsLoadMoreTableViewCell.h"

static NSString* const MITNewsCachedLayoutCellsAssociatedObjectKey = @"MITNewsCachedLayoutCells_NSMutableDictionary";

@interface MITNewsCategoryViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,strong) NSDate *lastUpdated;

@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *sizingCellBy;

@property (nonatomic,strong) NSString *searchQuery;

#pragma mark Table data sources
@property (nonatomic) NSUInteger numberOfStoriesPerPage;
@property (nonatomic,strong) NSArray *searchResults;
@property (nonatomic,strong) NSArray *newsStories;

@property (nonatomic,readonly) MITNewsStory *selectedStory;
@property (nonatomic,strong) MITNewsCategory *category;

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender;

#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingWithError:(NSError*)error animated:(BOOL)animate;
- (void)setToolbarString:(NSString*)string animated:(BOOL)animated;

#pragma mark UITableView Data Source Help
@end

@interface MITNewsCategoryViewController (DynamicTableViewCellsShared)
// I believe these methods shouldn't require modification to be used in another class.
- (NSMutableDictionary*)_cachedLayoutCellsForTableView:(UITableView*)tableView;
- (UITableViewCell*)_tableView:(UITableView*)tableView dequeueReusableLayoutCellWithIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath;
- (NSInteger)_tableView:(UITableView*)tableView minimumHeightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)_tableView:(UITableView*)tableView registerClass:(Class)nilOrClass forCellReuseIdentifier:(NSString*)cellReuseIdentifier;
- (void)_tableView:(UITableView*)tableView registerNib:(UINib*)nilOrNib forCellReuseIdentifier:(NSString*)cellReuseIdentifier;
@end

@interface MITNewsCategoryViewController (DynamicTableViewCells)
// You'll need to modify these for them to work in another class
// TODO: these should be delegated out (somehow)
- (NSInteger)_tableView:(UITableView *)tableView primitiveNumberOfRowsInSection:(NSInteger)section;
- (id)_tableView:(UITableView*)tableView representedObjectForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)_tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
- (NSString*)_tableView:(UITableView*)tableView reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath;
@end

@interface MITNewsCategoryViewController (NewsSearching)
// These methods are in the order they will (at least, should) be called in
- (void)beginSearchingAnimated:(BOOL)animated;
- (void)willLoadSearchResultsAnimated:(BOOL)animate;

- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion;
- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion;

- (void)didLoadResultsForSearchWithError:(NSError*)error animated:(BOOL)animate;
- (void)endSearchingAnimated:(BOOL)animated;

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView;
- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller;
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller;
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString;
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
@end

@implementation MITNewsCategoryViewController {
    NSManagedObjectID *_categoryObjectID;

    CGPoint _contentOffsetToRestoreAfterSearching;
    id _storySearchInProgressToken;
    id _storyUpdateInProgressToken;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [self _tableView:self.tableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
    
    if (self.numberOfStoriesPerPage == 0) {
        self.numberOfStoriesPerPage = MITNewsDefaultNumberOfStoriesPerPage;
    }
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlWasTriggered:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.isSearching) {
        __block NSString *title = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if (self.category) {
                title = self.category.name;
            } else {
                title = @"Top Stories";
            }
        }];
        
        self.title = title;
        if (!self.newsStories) {
            __weak MITNewsCategoryViewController *weakSelf = self;
            [self fetchFirstPageOfStoriesForCurrentCategory:^{
                MITNewsCategoryViewController *blockSelf = weakSelf;
                if (blockSelf) {
                    [self.tableView reloadData];
                }
            }];
        }
        
        if (self.lastUpdated) {
            NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                                toDate:[NSDate date]];
            NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
            [self setToolbarString:updateText animated:NO];
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
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext objectWithID:[story objectID]];
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter/Getter Implementations
- (NSMapTable*)gestureRecognizersByView
{
    if (!_gestureRecognizersByView) {
        _gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    }
    
    return _gestureRecognizersByView;
}

#pragma mark Category Management
- (MITNewsCategory*)category
{
    if (!_category) {
        if (_managedObjectContext && _categoryObjectID) {
            _category = (MITNewsCategory*)[_managedObjectContext objectWithID:_categoryObjectID];
        }
    }
    
    return _category;
}

- (void)setCategoryWithObjectID:(NSManagedObjectID *)objectID
{
    if (_categoryObjectID != objectID) {
        _categoryObjectID = objectID;
        
        [self didChangeCategory];
    }
}

- (void)didChangeCategory
{
    _category = nil;
    
    if (self.category && self.isViewLoaded && self.view.superview) {
        __weak MITNewsCategoryViewController *weakSelf = self;
        [self fetchFirstPageOfStoriesForCurrentCategory:^{
            MITNewsCategoryViewController *blockSelf = weakSelf;
            if (blockSelf) {
                [self.tableView reloadData];
            }
        }];
    }
}

#pragma mark - Managing states
#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate
{
    if (!self.isUpdating) {
        self.updating = YES;
        
        if (!self.isSearching) {
            [self.refreshControl beginRefreshing];
            [self setToolbarString:@"Updating..." animated:animate];
        } else {
            
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
    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];
    
    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark Responding to UI events
- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    [self beginSearchingAnimated:NO];
}

- (IBAction)refreshControlWasTriggered:(UIRefreshControl*)sender
{
    self.lastUpdated = nil;
    
    __weak MITNewsCategoryViewController *weakSelf = self;
    [self fetchFirstPageOfStoriesForCurrentCategory:^{
        MITNewsCategoryViewController *blockSelf = weakSelf;
        if (blockSelf) {
            [blockSelf.tableView reloadData];
        }
    }];
}

#pragma mark Loading & updating, and retrieving data
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        
        [self didChangeManagedObjectContext];
    }
}

- (void)didChangeManagedObjectContext
{
    if (self.isSearching) {
        if (self.searchResults && self.managedObjectContext) {
            self.searchResults = [self.managedObjectContext transferManagedObjects:self.searchResults];
        } else {
            self.searchResults = nil;
        }
        
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        if (self.newsStories) {
            self.newsStories = [self.managedObjectContext transferManagedObjects:self.newsStories];
        } else {
            self.newsStories = nil;
        }
        
        [self.tableView reloadData];
    }
}

- (void)fetchFirstPageOfStoriesForCurrentCategory:(void (^)(void))completion
{
    // nil out the update in progress token so that when the request returns
    // it skips its update (since we'll be messing with the data source)
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
    
    if (_categoryObjectID) {
        MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:_categoryObjectID];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@",category];
    }
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    fetchRequest.fetchLimit = self.numberOfStoriesPerPage;
    fetchRequest.fetchOffset = 0;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        NSArray *results = nil;
        NSUInteger objectCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:nil];
        
        results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"failed to fetch stories from CoreData cache: %@",error);
            objectCount = NSNotFound;
        } else {
            self.newsStories = results;
        }
        
        BOOL shouldReloadStories = ((objectCount == NSNotFound) ||
                                    (objectCount < self.numberOfStoriesPerPage) ||
                                    (self.lastUpdated == nil));
        
        if (shouldReloadStories) {
            [self loadStoriesInCategory:self.category
                     shouldLoadNextPage:NO
                             completion:^(NSManagedObjectID *categoryID, NSError *error) {
                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                     if (completion) {
                                         completion();
                                     }
                                 }];
                             }];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (completion) {
                    completion();
                }
            }];
        }
    }];
}

- (void)loadStoriesInCategory:(MITNewsCategory*)category shouldLoadNextPage:(BOOL)shouldLoadNextPage completion:(void (^)(NSManagedObjectID *category,NSError *error))completion
{
    if (_storyUpdateInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored");
    }
    
    __block NSString *categoryIdentifier = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];
        categoryIdentifier = category.identifier;
    }];

    NSUInteger offset = 0;
    if (shouldLoadNextPage) {
        offset = [self.newsStories count];
    }

    NSUUID *requestUUID = [NSUUID UUID];
    _storyUpdateInProgressToken = requestUUID;

    [self beginUpdatingAnimated:YES];
    
    __weak MITNewsCategoryViewController *weakSelf = self;
    void (^requestCompletionBlock)(NSArray*, MITResultsPager*, NSError*error) = ^(NSArray *stories, MITResultsPager *pager, NSError *error) {
        MITNewsCategoryViewController *blockSelf = weakSelf;
        if (blockSelf) {
            BOOL isSameRequestToken = (blockSelf->_storyUpdateInProgressToken == requestUUID);
            
            if (isSameRequestToken) {
                _storyUpdateInProgressToken = nil;

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (!error) {
                        __block NSArray *localStories = nil;
                        [blockSelf.managedObjectContext performBlockAndWait:^{
                            localStories = [blockSelf.managedObjectContext transferManagedObjects:stories];
                        }];
                        
                        // If we are loading the next (or additional pages, in general)
                        // we should append the results onto the existing search results.
                        // Otherwise, just do a wholesale replacement of the content.
                        if (shouldLoadNextPage) {
                            NSMutableArray *updatedNewsStories = [NSMutableArray arrayWithArray:self.newsStories];
                            NSRange insertionRange = NSMakeRange(offset, [stories count]);
                            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
                            
                            if (offset < [updatedNewsStories count]) {
                                [updatedNewsStories removeObjectsInRange:NSMakeRange(offset, [updatedNewsStories count])];
                            }
                            
                            [updatedNewsStories insertObjects:stories atIndexes:insertedIndexes];
                            blockSelf.newsStories = updatedNewsStories;
                        } else {
                            blockSelf.newsStories = localStories;
                        }
                        
                        [self endUpdatingAnimated:YES];
                        
                        if (completion) {
                            completion([category objectID],nil);
                        }
                    } else {
                        [self endUpdatingWithError:error animated:YES];
                        
                        if (completion) {
                            completion(nil,error);
                        }
                    }
                }];
            }
        }
    };

    self.updating = YES;
    [self.refreshControl beginRefreshing];
    [[MITNewsModelController sharedController] storiesInCategory:categoryIdentifier
                                                           query:nil
                                                          offset:offset
                                                           limit:20
                                                      completion:requestCompletionBlock];
    
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
    return [self _tableView:tableView representedObjectForRowAtIndexPath:selectedIndexPath];
}

#pragma mark - UITableView

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 22.;
    } else {
        return 0.;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.searchQuery) {
            UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsSearchHeader"];
            
            if (!headerView) {
                headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"NewsSearchHeader"];
            }
            
            if (_storySearchInProgressToken) {
                headerView.textLabel.text = [NSString stringWithFormat:@"loading results for '%@'",self.searchQuery];
            } else {
                headerView.textLabel.text = [NSString stringWithFormat:@"results for '%@'",self.searchQuery];
            }
            return  headerView;
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
    NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    
    // Go for the low-hanging fruit first
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return 44.;
    } else {
        return [self _tableView:tableView minimumHeightForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id representedObject = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    if (representedObject && [representedObject isKindOfClass:[MITNewsStory class]]) {
        [self performSegueWithIdentifier:@"showStoryDetail" sender:tableView];
    } else  {
        NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];

        if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
            if (tableView == self.tableView) {
                __weak UITableView *weakTableView = self.tableView;
                [self loadStoriesInCategory:self.category
                         shouldLoadNextPage:YES
                                 completion:^(NSManagedObjectID *category, NSError *error) {
                                     UITableView *blockTableView = weakTableView;
                                     if (blockTableView) {
                                         [blockTableView reloadData];
                                     }
                                 }];
            } else if (tableView == self.searchDisplayController.searchResultsTableView) {
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
        return (self.newsStories ? 1 : 0);
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
    NSString *reuseIdentifier = [self _tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(reuseIdentifier,@"[%@] missing UITableViewCell identifier in %@",self,NSStringFromSelector(_cmd));
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self _tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

@end

@implementation MITNewsCategoryViewController (DynamicTableViewCellsShared)
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
    layoutCell.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), cellSize.height + 16.);
    
    if (![layoutCell isDescendantOfView:tableView]) {
        [tableView addSubview:layoutCell];
    } else {
        [layoutCell prepareForReuse];
    }
    
    layoutCell.hidden = YES;
    [layoutCell.contentView setNeedsLayout];
    [layoutCell.contentView layoutIfNeeded];
    
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
    
    [layoutCell.contentView setNeedsUpdateConstraints];
    [layoutCell.contentView setNeedsLayout];
    [layoutCell.contentView layoutIfNeeded];
    
    CGSize rowSize = [layoutCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return (ceil(rowSize.height) + 6);
}

@end

@implementation MITNewsCategoryViewController (DynamicTableViewCells)
- (NSInteger)_tableView:(UITableView *)tableView primitiveNumberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        NSInteger numberOfRows = [self.newsStories count];
        
        if (numberOfRows > 0) {
            numberOfRows += 1; // Extra row for the 'Load More' cell
        }
        
        return numberOfRows;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        NSInteger numberOfRows = [self.searchResults count];
        
        if (numberOfRows > 0) {
            numberOfRows += 1; // Extra row for the 'Load More' cell
        }
        
        return numberOfRows;
    }
    
    return 0;
}

- (void)_tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (self.tableView == tableView) {
            cell.textLabel.enabled = !_storyUpdateInProgressToken;
        } else if (self.searchDisplayController.searchResultsTableView == tableView) {
            cell.textLabel.enabled = !_storySearchInProgressToken;
        }
    } else {
        id object = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
        
        if (object) {
            MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
            if ([storyCell respondsToSelector:@selector(setRepresentedObject:)]) {
                [storyCell setRepresentedObject:object];
            }
        }
    }
}

- (NSString*)_tableView:(UITableView*)tableView reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSInteger numberOfRowsInSection = [self _tableView:tableView primitiveNumberOfRowsInSection:indexPath];
    
    if (indexPath.row < (numberOfRowsInSection - 1)) {
        __block NSString *identifier = nil;
        MITNewsStory *story = [self _tableView:tableView representedObjectForRowAtIndexPath:indexPath];
        if (story) {
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
        }
        
        return identifier;
    } else {
        return MITNewsLoadMoreCellIdentifier;
    }
    
}

- (id)_tableView:(UITableView*)tableView representedObjectForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSUInteger row = (NSUInteger)indexPath.row;
    
    if (tableView == self.tableView) {
        if (row < [self.newsStories count]) {
            return self.newsStories[row];
        } else {
            return nil;
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (row < [self.searchResults count]) {
            return self.searchResults[row];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}
@end


@implementation MITNewsCategoryViewController (NewsSearching)
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

                [self didLoadResultsForSearchWithError:Nil animated:YES];

                _storySearchInProgressToken = nil;
            }
        }];
    } else {
        NSUInteger offset = 0;
        if (loadNextPage) {
            offset = [self.searchResults count];
        }

        if (![self.searchQuery isEqualToString:query]) {
            self.searchResults = @[];
        }

        self.searchQuery = query;

        [self willLoadSearchResultsAnimated:YES];

        __weak MITNewsCategoryViewController *weakSelf = self;
        [[MITNewsModelController sharedController] storiesInCategory:nil query:query offset:offset limit:20 completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
            MITNewsCategoryViewController *blockSelf = weakSelf;
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

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    [controller.searchBar becomeFirstResponder];
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
